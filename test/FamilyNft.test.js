const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('FamilyNft contract', () => {
    let family, deployer, minter, attacker

    beforeEach(async () => {
        ;[deployer, minter, owner] = await ethers.getSigners()
        const FAMILY = await ethers.getContractFactory('FamilyNft')
        family = await FAMILY.deploy()
    })

    describe('FamilyNft.sol Deployment', () => {
        it('Should set the deployer as the contract owner', async () => {
            expect(await family.owner()).to.equal(deployer.address)
        })
    })

    describe('Mint function', () => {
        it('should increment the count by 1', async () => {
            const before = await family.getCount()
            await family.mint(minter.address, '')
            const after = await family.getCount()
            expect(after).to.equal(before + 1)
        })
        it('should reject mint attempts who are not Deployer', async () => {
            unauthMint = family.mint(minter.address, '', {
                from: minter.address,
            })
            expect(unauthMint).to.be.reverted
        })
        it('should allow Deployer to call mint (test explicitly)', async () => {
            authMint = family.mint(minter.address, '', {
                from: deployer.address,
            })
            expect(authMint).not.to.be.reverted
        })
    })

    describe('getMinter()', () => {
        it('should return the minters address', async () => {
            await family.mint(minter.address, '')
            const result = await family.getMinter(
                ethers.utils.hexZeroPad('0x00', 32) // bytes32 tokenId
            )
            expect(result).to.equal(minter.address)
        })
        it('should revert if tokenId not recognised', async () => {
            await family.mint(minter.address, '')
            const result = family.getMinter(
                ethers.utils.hexZeroPad('0x99', 32) // bytes32 tokenId
            )
            expect(result).to.be.revertedWith('TokenId does not exist')
        })
    })

    describe('getMetadata()', () => {
        it('should return the token metaData as a string', async () => {
            await family.mint(minter.address, 'a')
            await family.mint(minter.address, 'b')
            const secondMint = await family.getMetadata(
                ethers.utils.hexZeroPad('0x01', 32) // bytes32 tokenId
            )
            expect(secondMint).to.equal('b')
        })
        it('should revert if tokenId not recognised', async () => {
            await family.mint(minter.address, '')
            const result = family.getMetadata(
                ethers.utils.hexZeroPad('0x99', 32) // bytes32 tokenId
            )
            expect(result).to.be.revertedWith('TokenId does not exist')
        })
    })
})
