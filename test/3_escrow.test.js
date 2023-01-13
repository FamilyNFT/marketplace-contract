const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('TESTING ESCROW FUNCTIONALITY', () => {
    let family, marketplace, deployer, minter, buyer, attacker, tokenId
    let PRICE = 100 // consider WEI vs ETH issue, what is this on LYX?
    let LYX_ONLY = [true, false, false]
    let escrowId

    before(async () => {
        ;[deployer, minter, buyer, attacker] = await ethers.getSigners()

        // 1 Deploy NFT contract and mint an NFT before each test in Marketplace
        const FAMILY = await ethers.getContractFactory('FamilyNft')
        family = await FAMILY.deploy()

        await family.mint(minter.address, 'abc123')
        tokenId = ethers.utils.hexZeroPad('0x00', 32) // bytes32 tokenId for NFT[0]

        // 2 Deploy Marketplace contracts
        const MARKETPLACE = await ethers.getContractFactory('LSP8Marketplace')
        marketplace = await MARKETPLACE.deploy()

        // 3 Approve Marketplace as operator for NFT –– needs to happen before listing
        await family
            .connect(minter)
            .authorizeOperator(marketplace.address, tokenId)

        // 4 List NFT (TokenId 0x00) for sale
        await marketplace
            .connect(minter)
            .putLSP8OnSale(family.address, tokenId, PRICE, LYX_ONLY)

        //-----key console.log checks
        // console.log('Family     ', family.address)
        // console.log('Marketplace', marketplace.address)
    })

    describe('escrow_When a buyer meets the asking price', () => {
        it('Should emit Event "Transfer"', async () => {
            await expect(
                marketplace
                    .connect(buyer)
                    .buyLSP8WithLYX(family.address, tokenId, {
                        value: PRICE,
                    })
            ).to.emit(marketplace, 'Action')
        })
        it('and therefore expect totalItems() to equal one', async () => {
            totalItems = await marketplace.getTotalItems()
            expect(totalItems.toNumber()).to.equal(1)
        })
        it('Should give correct seller (minter) and buyer (buyer) address', async () => {
            escrowId = await marketplace.getItemIdOfToken(
                family.address,
                tokenId
            )
            const fromEscrow = await marketplace.getBuyerSeller(escrowId)
            const fromTesting = [buyer.address, minter.address]
            expect(fromEscrow).to.eql(fromTesting)
        })
        it('Should revert premature withdrawl attempts by buyer', async () => {
            await expect(
                marketplace.connect(buyer).transferAssetsLSP8LYX(0)
            ).to.be.revertedWith(
                'Both parties must agree on success before transfer.'
            )
        })
        it('EscrowStatus = DISRUPTED if at least one party reports DISPUTE', async () => {
            await marketplace.connect(minter).reportDeliverySuccess(escrowId)
            await marketplace.connect(buyer).reportDispute(escrowId)
            expect(await marketplace.getEscrowStatus(escrowId)).to.equal(3)
        })
        it('EscrowStatus = SUCCESS if second party reports success', async () => {
            await marketplace.connect(buyer).reportDeliverySuccess(escrowId)
            expect(await marketplace.getEscrowStatus(escrowId)).to.equal(1)
        })
        it('Should then allow assets to be collected', async () => {
            await expect(
                await marketplace
                    .connect(minter)
                    .transferAssetsLSP8LYX(escrowId)
            ).to.emit(marketplace, 'Transfer')
        })
        it('should reject repeat attempts to withdraw', async () => {
            await expect(
                marketplace.connect(buyer).transferAssetsLSP8LYX(escrowId)
            ).to.revertedWith('Escrow item has been closed.')
        })
        it('should update escrow status to CLOSED and prevent further interaction', async () => {
            expect(await marketplace.getEscrowStatus(escrowId)).to.equal(4)
        })
    })
})
