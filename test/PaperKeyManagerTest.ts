import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Wallet } from "ethers";
import { ethers, upgrades } from "hardhat";
import { PaperKeyManagerTest } from "../typechain-types";

const IERC20 =
  "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol:ERC20Upgradeable";

describe("PaperKeyManagerTest", function () {
  const GasOverrides = {
    gasLimit: 1_000_000,
    maxFeePerGas: ethers.utils.parseUnits("200", "gwei"),
    maxPriorityFeePerGas: ethers.utils.parseUnits("50", "gwei"),
  };
  const PAPER_KEY_MANAGER_ADDRESS_MAINNET =
    "0x678a3F64A1bF33Ba0746fFD88Ba749B40B565Da5";
  const publicPrivateKey = ethers.Wallet.createRandom();

  async function DeployPaperKeyManagerTest() {
    const [owner, randomAccount1] = await ethers.getSigners();

    const contract = await ethers.getContractFactory("PaperKeyManagerTest");
    contract.connect(owner);
    const deployingContract = await contract.deploy(
      PAPER_KEY_MANAGER_ADDRESS_MAINNET
    );
    const deployedContract =
      (await deployingContract.deployed()) as PaperKeyManagerTest;
    return {
      contract: deployedContract,
      constructorArgs: [PAPER_KEY_MANAGER_ADDRESS_MAINNET],
      owner,
      randomAccount1,
    };
  }

  function getSignatureNonce(length: number = 31) {
    const possible =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let text = "";
    for (let i = 0; i < length; i++) {
      text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
  }

  async function createDefaultSignatureFrom(signer: Wallet) {
    const nonce = ethers.utils.formatBytes32String(getSignatureNonce());
    const data = [ethers.utils.formatBytes32String("")];
    const dataType = ["bytes32"];
    const packedData = ethers.utils.defaultAbiCoder.encode(dataType, data);
    const encodedData = ethers.utils.solidityKeccak256(["bytes"], [packedData]);
    const dataToSign = ethers.utils.arrayify(
      ethers.utils.solidityKeccak256(
        ["bytes32", "bytes32"],
        [encodedData, nonce]
      )
    );

    const signature = await signer.signMessage(dataToSign);
    const recoveredAddr = ethers.utils.recoverAddress(
      ethers.utils.hashMessage(dataToSign),
      signature
    );
    return {
      signature,
      data,
      dataType,
      packedData,
      encodedData,
      nonce,
      recoveredAddr,
    };
  }

  describe("Deployment", function () {
    it("Should set the PaperKeyManagerAddress", async function () {
      const { contract } = await loadFixture(DeployPaperKeyManagerTest);

      expect(await contract.paperKeyManager()).to.be.equal(
        PAPER_KEY_MANAGER_ADDRESS_MAINNET
      );
    });
  });

  describe("PaperKeyManager functions", function () {
    it("Should be able to register key manager", async function () {
      const { contract } = await loadFixture(DeployPaperKeyManagerTest);
      expect(
        await contract.registerPaperKey(publicPrivateKey.address, GasOverrides)
      ).to.emit(contract, "Registered");
    });
    it("Should not be able to register once the key has been registered", async function () {
      const { contract } = await loadFixture(DeployPaperKeyManagerTest);
      await contract.registerPaperKey(publicPrivateKey.address);
      await expect(
        contract.registerPaperKey(publicPrivateKey.address, GasOverrides)
      ).to.be.revertedWith("contract already registered");
    });

    it("Should be able to verify", async function () {
      const { contract } = await loadFixture(DeployPaperKeyManagerTest);
      const { nonce, signature } = await createDefaultSignatureFrom(
        publicPrivateKey
      );
      await contract.registerPaperKey(publicPrivateKey.address);

      await expect(contract.verifySignature(nonce, signature)).to.emit(
        contract,
        "Verified"
      );
    });

    it("Should not be able to verify once signature and nonce is already used", async function () {
      const { contract } = await loadFixture(DeployPaperKeyManagerTest);
      const { nonce, signature } = await createDefaultSignatureFrom(
        publicPrivateKey
      );

      await contract.registerPaperKey(publicPrivateKey.address);
      await contract.verifySignature(nonce, signature);
      await expect(
        contract.verifySignature(nonce, signature)
      ).to.be.revertedWith("Signature already used");
    });
  });
});
