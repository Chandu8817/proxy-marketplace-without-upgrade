const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ProxyAtMarketPlace", function () {

    let proxyOnMarketPlace;
    let proxy
    let accounts;
    let user1, user2, user3, user4, user5, user6

    before(async function () {
        accounts = await ethers.getSigners();
        [user1, user2, user3, user4, user5, user6] = accounts;
        const MarketPlace = await ethers.getContractFactory("MarketPlace");
        const marketPlace = await MarketPlace.deploy();
        await marketPlace.deployed();
        const Proxy = await ethers.getContractFactory("ProxyContract");
        proxy = await Proxy.deploy(marketPlace.address, "0x");
        await proxy.deployed();

        proxyOnMarketPlace = MarketPlace.attach(proxy.address);

    });

    describe("marketplace functionality on proxy contract ", async function () {


        it("Should mint NFT", async function () {
            await proxyOnMarketPlace.mint("hello world");
            console.log(await proxyOnMarketPlace.ownerOf(1), "owner of token 1");
            expect(await proxyOnMarketPlace.ownerOf(1)).to.be.equal(user1.address)


        });
        it("Should list  NFT for Rent", async function () {
            await proxyOnMarketPlace.ListNFTForRent(1);
            expect(await proxyOnMarketPlace.ListNftOnRent(1)).to.be.equal(true)


        });
        it("Should unlist  NFT from Rent", async function () {
            await proxyOnMarketPlace.mint("hello world second nft");
            await proxyOnMarketPlace.ListNFTForRent(2);
            console.log(`NFF show for Rent before unlist ${await proxyOnMarketPlace.ListNftOnRent(2)}`);
            await proxyOnMarketPlace.UnListNFTFromRent(2);
            console.log(`NFF not show for Rent After unlist ${await proxyOnMarketPlace.ListNftOnRent(2)}`);
            expect(await proxyOnMarketPlace.ListNftOnRent(2)).to.be.equal(false)
        });

        it("Should  Buy NFT on Rent", async function () {
            await proxyOnMarketPlace.connect(user2).RentNFT(1, { value: ethers.BigNumber.from(10000) });
            expect(await proxyOnMarketPlace.NftRentBy(1)).to.be.equal(user2.address)

        });
        it("Should get NFT on Rent ", async function () {
            let RentDetails = await proxyOnMarketPlace.getRentNFT(1, user2.address)
            console.log(`owner of NFT is ${RentDetails[0]} and NFT is on Rent is ${RentDetails[1]}`);
            expect(RentDetails[0]).to.be.equal(user1.address);

        });

    });

    describe("Proxy contract Functionality", async function () {

        let erc721Contract

        before(async function () {
            let ERC721 = await ethers.getContractFactory("GameItem");

            erc721Contract = await ERC721.deploy();
            await erc721Contract.deployed();
        });


        it("Should make offer for NFT ", async function () {
            await erc721Contract.connect(user3).awardItem(user3.address, "gameToken");
            await proxy.connect(user4).MakeAnOffer(erc721Contract.address, "1", ethers.BigNumber.from(1000000), { value: ethers.BigNumber.from(1000000) })

        });
        it("Should fetch NFT offer ", async function () {
            let offerDetails = await proxy.FetchAnOffer(erc721Contract.address, 1)
            console.log(offerDetails);
        });

        it("Should Accept NFT offer ", async function () {
            await erc721Contract.connect(user3).approve(proxy.address, 1)
            await proxy.connect(user3).AcceptOffer(erc721Contract.address, 1)
            console.log(`New owner ${await erc721Contract.ownerOf(1)}`);
            expect(await erc721Contract.ownerOf(1)).to.be.equal(user4.address)
        });

        it("Should Reject Offer ", async function () {
            await proxy.connect(user5).MakeAnOffer(erc721Contract.address, "1", ethers.BigNumber.from(1000000), { value: ethers.BigNumber.from(1000000) })

            await proxy.connect(user4).RejectOffer(erc721Contract.address, "1")
            let offerDetails = await proxy.FetchAnOffer(erc721Contract.address, 1)
            console.log(offerDetails);
            // expect(await offerDetails.offerBy).to.be.equal(user4.address)
        });
    });

});