pragma solidity ^0.8.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import { ISuperfluid, ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { IConstantFlowAgreementHook } from "./IConstantFlowAgreementHook.sol";
import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

/*
* NFT representing a flow that points to offchain data, created by CFAv1 hook or manual minting
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

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    string public name;
    string public symbol;
    string public baseUrl = "https://superfluid-nft.netlify.app/.netlify/functions/getmeta";
    IConstantFlowAgreementV1 public cfaV1;
    uint256 public tokenIds;
    mapping(uint256 => FlowData) internal _flowDataById;
    mapping(bytes32 => uint256) internal _idByFlowKey;
    //mapping(uint256 => address) internal _ownerOf;

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
            '&start_date=',uint256(flowData.startDate).toString()
        ));
    }

    constructor(address cfa, string memory _name, string memory _symbol) {
        cfaV1 = IConstantFlowAgreementV1(cfa);
        name = _name;
        symbol = _symbol;
    }

    // ============= IConstantFlowAgreementHook interface =============

    function onCreate(ISuperfluidToken token, CFAHookParams memory newFlowData) public returns(bool) {
        tokenIds++;
        _mint(tokenIds, address(token), newFlowData.sender, newFlowData.receiver, uint64(block.timestamp));
        return true;
    }

    function onUpdate(ISuperfluidToken token, CFAHookParams memory updatedFlowData, int96 oldFlowRate) public returns(bool) {
        return true;
    }

    function onDelete(ISuperfluidToken token, CFAHookParams memory updatedFlowData, int96 oldFlowRate) public returns(bool) {
        _burn(address(token), updatedFlowData.sender, updatedFlowData.receiver);
        return true;
    }

    // ============= ERC721 interface =============

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _flowDataById[id].receiver;
        if(owner == address(0)) revert NOT_EXISTS();
    }

    // TODO: is this safe? Avoids more storage.
    function balanceOf(address owner) public view virtual returns (uint256) {
        return 1;
    }

    // ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // Interface ID for ERC165
            interfaceId == 0x80ac58cd || // Interface ID for ERC721
            interfaceId == 0x5b5e139f; // Interface ID for ERC721Metadata
    }

    function approve(address spender, uint256 id) public {
        revert NOT_AVAILABLE();
    }

    function setApprovalForAll(address operator, bool approved) public {
        revert NOT_AVAILABLE();
    }

    function transferFrom(address from,address to,uint256 id) public {
        revert NOT_AVAILABLE();
    }

    function safeTransferFrom(address from,address to,uint256 id) public {
        revert NOT_AVAILABLE();
    }

    function safeTransferFrom(address from, address to, uint256 id,bytes calldata data) public {
        revert NOT_AVAILABLE();
    }

    function _getFlowRate(address token, address sender, address receiver) internal view returns(int96 flowRate) {
        (,flowRate,,) = cfaV1.getFlow(ISuperToken(token), sender, receiver);
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

    // ============= debugging fns TODO: renove =============

    function mint(address token, address sender, address receiver)  public {
        int96 flowRate = _getFlowRate(token, sender, receiver);
        if(flowRate > 0) {
            tokenIds++;
            _mint(tokenIds, token, sender, receiver, uint64(block.timestamp));
        } else {
            revert NOT_EXISTS();
        }
    }

/*
    error NOT_STREAM_USER();
    function burn(address token, address sender, address receiver) public {
        if(msg.sender != receiver) revert NOT_STREAM_USER();
        int96 flowRate = _getFlowRate(token, sender, receiver);
        if(flowRate == 0) {
            _burn(token, sender, receiver);
        }
    }
    */
}