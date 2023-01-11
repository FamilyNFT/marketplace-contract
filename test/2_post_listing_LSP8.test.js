const { expect } = require('chai')
const { ethers } = require('hardhat')

// TODO
// Note that the bool isOnSale() function in LSP8MarketplaceSale.sol was created just for
// ease of testing and will need deleting.

describe('LSP8 post-listing, making an offer', () => {
    let family, marketplace, deployer, owner, buyer, attacker, tokenId
    let PRICE = 100 // consider WEI vs ETH issue, what is this on LYX?
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

        // 4 an list NFT (TokenId 0x00) for sale
        await marketplace
            .connect(owner)
            .putLSP8OnSale(family.address, tokenId, PRICE, LYX_ONLY)
    })

    describe('After an LSP8 has been listed for sale', () => {
        it('Owner can change price using changeLYXPrice', async () => {
            const NEW_PRICE = 200
            await marketplace
                .connect(owner)
                .changeLYXPrice(family.address, tokenId, NEW_PRICE)
            const price = await marketplace._returnLYXPrice(
                family.address,
                tokenId
            )
            expect(price).to.equal(NEW_PRICE)
        })

        it('Owner can delist using removeLSP8FromSale and revoke marketplace using revokeOperator', async () => {
            await family
                .connect(owner)
                .revokeOperator(marketplace.address, tokenId)
            await marketplace
                .connect(owner)
                .removeLSP8FromSale(family.address, tokenId)
            check = [
                await family.isOperatorFor(marketplace.address, tokenId),
                await marketplace.isOnSale(family.address, tokenId),
            ]
            expect(check).to.eql([false, false])
        })

        it('Buyer can purchase by sending enough LYX using buyLSP8WithLYX', async () => {
            const before = await marketplace.isOnSale(family.address, tokenId)
            await marketplace
                .connect(buyer)
                .buyLSP8WithLYX(family.address, tokenId, {
                    value: PRICE,
                })
            const after = await marketplace.isOnSale(family.address, tokenId)
            check = [before, after]
            expect(check).to.eql([true, false])
        })
    })
})
