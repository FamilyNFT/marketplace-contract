const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('LSP8 before listing, Authorise Marketplace and test putLSP8OnSale()', () => {
    let family, marketplace, deployer, owner, buyer, attacker, tokenId
    let PRICE = 100
    let LYX_ONLY = [true, false, false]

    before(async () => {
        ;[deployer, owner, buyer, attacker] = await ethers.getSigners()

        // 1 deploy NFT contract and mint an NFT before each test in Marketplace
        const FAMILY = await ethers.getContractFactory('FamilyNft')
        family = await FAMILY.deploy()
        await family.mint(owner.address, 'abc123')
        tokenId = ethers.utils.hexZeroPad('0x00', 32) // bytes32 tokenId for NFT[0]

        // 2 deploy Marketplace contract
        const MARKETPLACE = await ethers.getContractFactory('LSP8Marketplace')
        marketplace = await MARKETPLACE.deploy()

        // 3 approve Marketplace as operator for NFT –– needs to happen before listing
        await family
            .connect(owner)
            .authorizeOperator(marketplace.address, tokenId)
    })

    describe('When approving marketplace as operator', () => {
        it('Should allow owner to approve Marketplace as operator of LSP8', async () => {
            expect(
                await family
                    .connect(owner)
                    .authorizeOperator(marketplace.address, tokenId)
            ).to.be.ok
        })
        it('Should revert addresses other than owner -- attacker', async () => {
            await expect(
                family
                    .connect(attacker)
                    .authorizeOperator(marketplace.address, tokenId)
            ).to.be.reverted
        })
        it('Should revert addresses other than owner -- deployer', async () => {
            await expect(
                family
                    .connect(deployer)
                    .authorizeOperator(marketplace.address, tokenId)
            ).to.be.reverted
        })
    })

    describe('Before LSP8 is on sale...', () => {
        it('changeLYXPrice should revert', async () => {
            // console.log(
            //     '--token on sale?',
            //     await marketplace.isOnSale(family.address, tokenId)
            // )
            const NEW_PRICE = 200
            await expect(
                marketplace
                    // await marketplace
                    .connect(owner)
                    .changeLYXPrice(family.address, tokenId, NEW_PRICE)
            ).to.be.revertedWith('LSP8 is not on sale.')
            // problem with chai not picking up the revert message which happens as expected
            // uncomment and use await.marketplace to see the revert message
        })
    })

    describe('When putting an LSP8 on sale using putLSP8OnSale()', () => {
        it('Should list LSP8 when owner calls', async () => {
            expect(
                marketplace
                    .connect(owner)
                    .putLSP8OnSale(family.address, tokenId, PRICE, LYX_ONLY)
            ).to.be.ok
        })
        it('Should revert addresses other than owner', async () => {
            await expect(
                marketplace
                    .connect(deployer)
                    .putLSP8OnSale(family.address, tokenId, PRICE, LYX_ONLY)
            ).to.be.revertedWith("Sender doesn't own this LSP8.")
        })
        it('Should be priced at the listed price', async () => {
            const price = await marketplace._returnLYXPrice(
                family.address,
                tokenId
            )
            expect(price).to.equal(PRICE)
        })
        it('Should match specified accepted offer types', async () => {
            const acceptedOffers = await marketplace._returnOfferAlowance(
                family.address,
                tokenId
            )
            expect(acceptedOffers).to.eql(LYX_ONLY)
        })
    })
})
