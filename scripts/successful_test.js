const hre = require('hardhat')
const { ethers } = require('hardhat')

// returns a bytes32 tokenId
function tokenId(id) {
    return ethers.utils.hexZeroPad(ethers.utils.hexlify(id), 32)
}

//  ---MINT NFTs for minter and minter1
async function mintNFTs() {
    // mint 3 NFTs for minter
    await family.mint(minter.address, '')
    await family.mint(minter.address, '')
    await family.mint(minter.address, '')

    // mint 2 NFTs for minter1
    await family.connect(deployer).mint(minter1.address, '')
    await family.connect(deployer).mint(minter1.address, '')

    console.log('Total NFTs minted =', await family.totalSupply())
    console.log('\n-------')
    console.log('Minter balance =', await family.getBalanceof(minter.address))
    console.log('Minter1 balance =', await family.getBalanceof(minter1.address))
}

// ---DEPLOY CONTRACTS
async function main() {
    const [deployer, minter1, minter2, buyer, attacker] =
        await ethers.getSigners()
    dplr = deployer.address
    m1 = minter1.address
    m2 = minter2.address
    buyr = buyer.address
    atkr = attacker.address

    const m1_bal = await ethers.provider.getBalance(m1)

    let PRICE = ethers.utils.parseEther('100') // consider WEI vs ETH issue, what is this on LYX?
    let LYX_ONLY = [true, false, false]
    let escrowId

    const FAMILY = await hre.ethers.getContractFactory('FamilyNft')
    const family = await FAMILY.deploy()
    await family.deployed()
    console.log('\n', 'FamilyNft deployed to:', family.address)

    const MARKETPLACE = await hre.ethers.getContractFactory('LSP8Marketplace')
    const marketplace = await MARKETPLACE.deploy()
    await marketplace.deployed()
    console.log('Marketplace deployed to:', marketplace.address)
    console.log('Deployer: ', await family.owner())

    // ---MINT NFTs for minter and minter1

    // mint 2 NFTs for minter1
    await family.mint(m1, '')
    await family.mint(m1, '')
    await family.mint(m1, '')

    // mint 2 NFTs for minter2
    await family.mint(m2, '')
    await family.mint(m2, '')

    console.log('Total NFTs minted =', (await family.totalSupply()).toNumber())
    console.log('minter1 balance =', (await family.balanceOf(m1)).toNumber())
    console.log('minter2 balance =', (await family.balanceOf(m2)).toNumber())
    console.log('\n-------')

    // ---Place NFTs on sale (minter 1)
    console.log('Listing NFT for sale...')
    await family
        .connect(minter1)
        .authorizeOperator(marketplace.address, tokenId(0))
    console.log('...Marketplace authorized to transfer NFT')
    await marketplace
        .connect(minter1)
        .putLSP8OnSale(family.address, tokenId(0), PRICE, LYX_ONLY)
    console.log('...NFT [0] listed for sale!')
    console.log('...checking owner [0]:', await family.tokenOwnerOf(tokenId(0)))
    console.log('\n-------')

    // ---Buyer purchases NFT[0], assets sent to Escrow
    console.log(
        'Making offer of',
        ethers.utils.formatEther(PRICE).toString(),
        'for LSP8[0]...'
    )
    await marketplace
        .connect(buyer)
        .buyLSP8WithLYX(family.address, tokenId(0), {
            value: PRICE,
        })

    console.log('...Success! Token [0] transferred to marketplace Escrow')
    console.log('...checking owner [0]:', await family.tokenOwnerOf(tokenId(0)))

    let mp_bal = ethers.utils.formatEther(await marketplace.getBalance())
    let mpcBal = await ethers.provider.getBalance(marketplace.address)
    let m1bal = await ethers.provider.getBalance(m1)
    let byrbal = await ethers.provider.getBalance(buyr)
    console.log('......escrow balance:', mp_bal)
    console.log('......mPlace balance:', ethers.utils.formatEther(mpcBal))
    console.log('......mint1 balance::', ethers.utils.formatEther(m1bal))
    console.log('......buyer balance:', ethers.utils.formatEther(byrbal))

    let e_id = await marketplace.getItemIdOfToken(family.address, tokenId(0))
    console.log('...Your escrowId is', e_id.toNumber())
    console.log('...seller has been notified')
    console.log('...upon receipt, please call confirmReceipt()')
    console.log('\n-------')

    // // ---A) after successful delivery, buyer call  and funds transferred
    // console.log('Item received. Buyer scans NFC tag and calls SUCCESS...')
    // await marketplace.connect(buyer).confirmReceipt(0)
    // console.log('...Success! Token [0] transferred to buyer')
    // console.log('...checking owner [0]:', await family.tokenOwnerOf(tokenId(0)))

    // // ---B) there's a problem – seller calls withdraw.
    // console.log('IRL stock is damaged. seller calls WITHDRAW...')
    // await marketplace.connect(minter1).reportWithdraw(0)
    // console.log('...Success! Token [0] returned to seller')
    // console.log('...checking owner [0]:', await family.tokenOwnerOf(tokenId(0)))

    // ---C) buyer suspects it's a scam – buyer calls dispute.
    // console.log('something seems fishy. buyer calls DISPUTE...')
    // await marketplace.connect(buyer).reportDispute(0)
    // console.log('...Confirmed. Assets sent to Family TREASURY')
    // console.log('...checking owner [0]:', await family.tokenOwnerOf(tokenId(0)))

    // ---check balances
    mp_bal = ethers.utils.formatEther(await marketplace.getBalance())
    mpcBal = await ethers.provider.getBalance(marketplace.address)
    m1bal = await ethers.provider.getBalance(m1)
    byrbal = await ethers.provider.getBalance(buyr)
    console.log('......escrow balance:', mp_bal)
    console.log('......mPlace balance:', ethers.utils.formatEther(mpcBal)) //.toNumber())
    console.log('......mint1 balance::', ethers.utils.formatEther(m1bal))
    console.log('......buyer balance:', ethers.utils.formatEther(byrbal))
    // console.log('...checking reclaim attempt:')
    // await marketplace.connect(buyer).confirmReceipt(0)
    console.log('\n-------')

    // ---attacker attempts
    const mpAdd = marketplace.address
    const fAdd = family.address
    console.log('Testing attacker attempts...:')
    console.log('...on mint LSP8')
    // await family.connect(attacker).mint(atkr, '')

    console.log('...on sell LSP8')
    // await marketplace
    //     .connect(attacker)
    //     .putLSP8OnSale(fAdd, tokenId(0), PRICE, LYX_ONLY)

    console.log('...to claim escrow LSP8')
    // await marketplace.connect(attacker).confirmReceipt(0)
    // await marketplace.connect(attacker).reportWithdraw(0)
    // await marketplace.connect(attacker).reportDispute(0)

    console.log('...to change Treasury')
    await marketplace.connect(attacker).setTreasury(atkr)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
