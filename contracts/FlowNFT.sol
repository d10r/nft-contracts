// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import { ISuperfluid, ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { IConstantFlowAgreementHook } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementHook.sol";
import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/*
* NFT representing a flow that points to offchain data, created by CFAv1 hook or manual minting.
* The existence of a CFA flow doesn't guarantee the existence of a representing token,
* also a token may still exist after a flow has stopped.
* That's because the hooks are best-effort and allowed to fail e.g. if not enough gas was provided.
* There's a mint method which allows anybody to retroactively mint a token for an existing flow.
* Token owners (flow receivers) can anytime burn their token.
* Tokens representing a stopped flow can be recognized by their zero flowrate.
* If a flow is created again with a token for the previous flow (same token, sender, receiver)
* still existing, that token represents the new flow.
* Thus a flow with the same flowId (create -> delete -> create) may be represented by the same
* (if the token wasn't burned) or by a different (if the token was burned) token.
*/
contract FlowNFT is IConstantFlowAgreementHook {

    using Strings for uint256;

    struct FlowData {
        address token;
        address sender;
        address receiver;
        uint64 startDate;
    }

    /// thrown by methods not available, e.g. transfer
    error NOT_AVAILABLE();

    /// thrown when attempting to mint an NFT which already exists
    error ALREADY_MINTED();

    /// thrown when looking up a token or flow which doesn't exist
    error NOT_EXISTS();

    /// thrown when trying to mint to the zero address
    error ZERO_ADDRESS();

    /// thrown if a msg.sender doesn't have permission to execute an operation
    error NO_PERMISSION();

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    string public name;
    string public symbol;
    string public constant baseUrl = "https://nft.superfluid.finance/cfa/v1/getmeta";

    // incremented on every new mint and used as tokenId
    uint256 public tokenCnt;

    mapping(uint256 => FlowData) internal _flowDataById;
    mapping(bytes32 => uint256) internal _idByFlowKey;

    IConstantFlowAgreementV1 internal _cfaV1;

    constructor(address cfa_, string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        _cfaV1 = IConstantFlowAgreementV1(cfa_);
    }

    /// Allows retroactive minting to flow receivers if minting wasn't done via the hook.
    /// Can be triggered by anybody.
    function mint(address token, address sender, address receiver) public {
        int96 flowRate = _getFlowRate(token, sender, receiver);
        if(flowRate > 0) {
            tokenCnt++;
            _mint(tokenCnt, token, sender, receiver, 0);
        } else {
            revert NOT_EXISTS();
        }
    }

    /// Allows flow receivers to burn their NFTs
    function burn(address token, address sender, address receiver) public {
        if(msg.sender != receiver) revert NO_PERMISSION();
        _burn(token, sender, receiver);
    }

    /// returns the token id representing the given flow
    /// reverts if no token exist
    /// note that this method doesn't check if an actual flow currently exists for this params (flowrate != 0)
    function getTokenId(address token, address sender, address receiver) external view returns(uint256 tokenId) {
        bytes32 flowKey = keccak256(abi.encodePacked(
                token,
                sender,
                receiver
            ));
        tokenId = _idByFlowKey[flowKey];
        if(tokenId == 0) revert NOT_EXISTS();
    }

    // ============= IConstantFlowAgreementHook interface =============

    function onCreate(ISuperfluidToken token, CFAHookParams memory newFlowData) public returns(bool) {
        tokenCnt++;
        _mint(tokenCnt, address(token), newFlowData.sender, newFlowData.receiver, uint64(block.timestamp));
        return true;
    }

    function onUpdate(ISuperfluidToken /*token*/, CFAHookParams memory /*updatedFlowData*/, int96 /*oldFlowRate*/) public pure returns(bool) {
        return true;
    }

    function onDelete(ISuperfluidToken token, CFAHookParams memory updatedFlowData, int96 /*oldFlowRate*/) public returns(bool) {
        _burn(address(token), updatedFlowData.sender, updatedFlowData.receiver);
        return true;
    }

    // ============= ERC721 interface =============

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _flowDataById[id].receiver;
        if(owner == address(0)) revert NOT_EXISTS();
    }

    /// note that we can't rely on the startDate as a flow may have been deleted and re-crated in the meantime
    function tokenURI(uint256 id) public view returns (string memory) {
        FlowData memory flowData = _flowDataById[id];

        address receiver = ownerOf(id);
        return string(abi.encodePacked(
            baseUrl,
            '?token=', Strings.toHexString(uint256(uint160(flowData.token)), 20),
            '&token_symbol=', ISuperToken(flowData.token).symbol(),
            '&token_decimals=', uint256(ISuperToken(flowData.token).decimals()).toString(),
            '&sender=', Strings.toHexString(uint256(uint160(flowData.sender)), 20),
            '&receiver=', Strings.toHexString(uint256(uint160(receiver)), 20),
            '&flowRate=',uint256(uint96(_getFlowRate(flowData.token, flowData.sender, receiver))).toString(),
            flowData.startDate == 0 ? '' : '&start_date=',uint256(flowData.startDate).toString()
        ));
    }

    // always returns 1 in order to not waste storage
    function balanceOf(address owner) public view virtual returns (uint256) {
        if(owner == address(0)) revert ZERO_ADDRESS();
        return 1;
    }

    // ERC165 Interface Detection
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // Interface ID for ERC165
            interfaceId == 0x80ac58cd || // Interface ID for ERC721
            interfaceId == 0x5b5e139f; // Interface ID for ERC721Metadata
    }

    function approve(address /*spender*/, uint256 /*id*/) public pure {
        revert NOT_AVAILABLE();
    }

    function setApprovalForAll(address /*operator*/, bool /*approved*/) public pure {
        revert NOT_AVAILABLE();
    }

    function transferFrom(address /*from*/, address /*to*/, uint256 /*id*/) public pure {
        revert NOT_AVAILABLE();
    }

    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*id*/) public pure {
        revert NOT_AVAILABLE();
    }

    function safeTransferFrom(address /*from*/, address /*to*/, uint256 /*id*/, bytes calldata /*data*/) public pure {
        revert NOT_AVAILABLE();
    }

    // ============= private interface =============

    function _mint(uint256 id, address token, address sender, address receiver, uint64 startDate) internal {
        if(receiver == address(0)) revert ZERO_ADDRESS();
        bytes32 flowKey = keccak256(abi.encodePacked(
                token,
                sender,
                receiver
            ));
        if(_idByFlowKey[flowKey] != 0) revert ALREADY_MINTED();
        if(_flowDataById[id].receiver != address(0)) revert ALREADY_MINTED();
        _flowDataById[id] = FlowData(token, sender, receiver, startDate);
        _idByFlowKey[flowKey] = id;
        emit Transfer(address(0), receiver, id);
    }

    function _burn(address token, address sender, address receiver) internal {
        bytes32 flowKey = keccak256(abi.encodePacked(token, sender, receiver));
        uint256 id = _idByFlowKey[flowKey];
        if(id == 0) revert NOT_EXISTS();
        delete _flowDataById[id];
        delete _idByFlowKey[flowKey];
        emit Transfer(receiver, address(0), id);
    }

    function _getFlowRate(address token, address sender, address receiver) internal view returns(int96 flowRate) {
        (,flowRate,,) = _cfaV1.getFlow(ISuperToken(token), sender, receiver);
    }
}