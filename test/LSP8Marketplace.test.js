const { expect } = require('chai')
const { hre, ethers } = require('hardhat')

describe('LSP8Marketplace', () => {
    let family, marketplace, signer, deployer, minter, buyer, attacker
    let tokenId, accept_LYX

    // TO PRINT CONTRACT ABI
    // console.log(family)
    // console.log(marketplace)

    beforeEach(async () => {
        ;[deployer, minter, buyer, attacker] = await ethers.getSigners()

        // 1 deploy NFT contract and mint an NFT before each test in Marketplace
        const FAMILY = await ethers.getContractFactory('FamilyNft')
        family = await FAMILY.deploy()
        await family.mint(minter.address, 'abc123')
        tokenId = ethers.utils.hexZeroPad('0x00', 32) // bytes32 tokenId for NFT[0]

        // 2 deploy Marketplace contract
        const MARKETPLACE = await ethers.getContractFactory('LSP8Marketplace')
        marketplace = await MARKETPLACE.deploy()

        console.log('minter:', minter.address)
        console.log('family:', family.address)
        console.log('marketplace:', marketplace.address)

        console.log('tokenOwner[0]:', await family.tokenOwnerOf(tokenId))
    })

    // 3 test that the Marketplace contract is deployed correctly
    describe('putLSP8OnSale()', () => {
        it('NFT put on sale should be listed as for sale', async () => {
            marketplace.authorizeOperator(marketplace.address, tokenId)
            console.log('authorised operator:', marketplace.address)
            const tx = await marketplace
                .connect(minter)
                .putLSP8OnSale(family.address, tokenId, 100, [1, 0, 0])
            expect(tx).not.to.be.reverted
        })

        // it('Should revert if seller does not own NFT', async () => {
        //     tx = await marketplace
        //         .connect(minter)
        //         .putLSP8OnSale(family.address, tokenId, 100, [1, 0, 0])
        //     expect(tx).to.be.reverted
        // })
    })
})
