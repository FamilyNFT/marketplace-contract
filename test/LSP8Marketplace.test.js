const { expect } = require('chai')
const { sinon } = require('sinon')
const { ethers } = require('hardhat')

describe('LSP8Marketplace', () => {
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

        // 3 approve Marketplace as operator for NFT
        const tx = await family
            .connect(owner)
            .authorizeOperator(marketplace.address, tokenId)
    })

    // beforeEach(async () => {
    //     // console.log('owner:', owner.address)
    //     // console.log('FamilyNft:  ', family.address)
    //     // console.log('Marketplace:', marketplace.address)
    // })

    // describe('When approving marketplace as operator', () => {
    //     it('Should allow owner to approve Marketplace as operator of LSP8', async () => {
    //         const tx = await family
    //             .connect(owner)
    //             .authorizeOperator(marketplace.address, tokenId)
    //         expect(tx).to.emit(family.address, 'AuthorizedOperator')
    //     })
    //     it('Should revert addresses other than owner -- attacker', async () => {
    //         await expect(
    //             family
    //                 .connect(attacker)
    //                 .authorizeOperator(marketplace.address, tokenId)
    //         ).to.be.reverted
    //     })

    //     it('Should revert addresses other than owner -- deployer', async () => {
    //         await expect(
    //             family
    //                 .connect(deployer)
    //                 .authorizeOperator(marketplace.address, tokenId)
    //         ).to.be.reverted
    //     })
    // })

    // describe('When putting an LSP8 on sale using putLSP8OnSale()', () => {
    //     it('Should list LSP8 when owner calls', async () => {
    //         expect(
    //             marketplace
    //                 .connect(owner)
    //                 .putLSP8OnSale(family.address, tokenId, PRICE, LYX_ONLY)
    //         ).to.be.ok
    //     })
    //     it('Should revert addresses other than owner', async () => {
    //         await expect(
    //             marketplace
    //                 .connect(deployer)
    //                 .putLSP8OnSale(family.address, tokenId, PRICE, LYX_ONLY)
    //         ).to.be.revertedWith("Sender doesn't own this LSP8.")
    //     })
    //     it('Should be priced at the listed price', async () => {
    //         const price = await marketplace._returnLYXPrice(
    //             family.address,
    //             tokenId
    //         )
    //         expect(price).to.equal(PRICE)
    //     })
    //     it('Should match input accepted offers', async () => {
    //         const acceptedOffers = await marketplace._returnOfferAlowance(
    //             family.address,
    //             tokenId
    //         )
    //         expect(acceptedOffers).to.eql(LYX_ONLY)
    //     })
    // })

    // USING SINON TO TEST MODIFIERS
    // describe('test function modifiers', function() {
    //     it('tests a function modifier', function() {
    //       let myFunc = function() {};
    //       let spy = sinon.spy();
    //       myFunc = myFunc.before(spy);

    //       // call the original function
    //       myFunc();
    //       expect(spy.calledOnce).to.be.true;
    //     });
    //   });

    describe('When LSP8 has not yet been listed', () => {
        it('Should revert at LSP8NotForSale modifier', async () => {
            const NEW_PRICE = 200
            await expect(
                marketplace
                    .connect(owner)
                    .changeLYXPrice(family.address, tokenId, NEW_PRICE)
            ).to.revertedWith('LSP8 is not on sale.')
        })
        // it('Should revert if changeLYXPrice is called', async () => {
        //     const NEW_PRICE = 200
        //     await expect(
        //         marketplace
        //             .connect(owner)
        //             .changeLYXPrice(family.address, tokenId, NEW_PRICE)
        //     ).to.revertedWith('LSP8 is not on sale.')
        //     // await marketplace
        //     //     .connect(owner)
        //     //     .changeLYXPrice(family.address, tokenId, NEW_PRICE)

        //     // const price = await marketplace._returnLYXPrice(
        //     //     family.address,
        //     //     tokenId
        //     // )
        //     // console.log('price:', ethers.BigNumber.from(price).toNumber())
        // })
    })

    // LIST LSP8 FOR FURTHER TESTING

    before(async () => {
        await marketplace
            .connect(owner)
            .putLSP8OnSale(family.address, tokenId, PRICE, LYX_ONLY)
    })

    describe('After an LSP8 has been listed for sale', () => {
        it('Should reflect new price after owner calls using changeLYXPrice', async () => {
            const NEW_PRICE = 200
            const tx = await marketplace
                .connect(owner)
                .changeLYXPrice(family.address, tokenId, NEW_PRICE)
            const price = await marketplace._returnLYXPrice(
                family.address,
                tokenId
            )
            expect(price).to.equal(NEW_PRICE)
        })
    })

    // describe('When buying an LSP8 using buyLSP8()', () => {}
})
