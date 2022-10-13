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

    struct StreamData {
        address token;
        uint64 startDate;
        address sender;
    }

    error NOT_ALLOWED();
    error ALREADY_MINTED();
    error NOT_MINTED();
    error ZERO_ADDRESS();
    error EMPTY_DATA();
    error NOT_STREAM_USER();

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    string public name;
    string public symbol;
    string public url;
    IConstantFlowAgreementV1 public cfaV1;
    uint256 private _tokenIds;
    mapping(uint256 => StreamData) internal _tokenCFAData;
    mapping(bytes32 => uint256) internal _revertStreamToId;
    mapping(uint256 => address) internal _ownerOf;

    function tokenURI(uint256 id) public view returns (string memory) {
        StreamData memory stream = _tokenCFAData[id];

        address receiver = ownerOf(id);
        if(receiver == address(0)) return "";
        return string(abi.encodePacked(
                url,
                'token_symbol=', ISuperToken(stream.token).symbol(),
                '&token_decimals=', uint256(ISuperToken(stream.token).decimals()).toString(),
                '&sender=', Strings.toHexString(uint256(uint160(stream.sender)), 20),
                '&receiver=', Strings.toHexString(uint256(uint160(receiver)), 20),
                '&flowRate=',uint256(uint96(_getFlowRate(stream.token, stream.sender, receiver))).toString(),
                '&start_date=',uint256(stream.startDate).toString()
        ));
    }

    constructor(address cfa, string memory _name, string memory _symbol) {
        cfaV1 = IConstantFlowAgreementV1(cfa);
        name = _name;
        symbol = _symbol;
    }

    // ============= IConstantFlowAgreementHook interface =============

    function onCreate(ISuperfluidToken token, CFAHookParams memory newFlowData) public returns(bool) {
        _tokenIds++;
        _mint(_tokenIds, address(token), newFlowData.sender, newFlowData.receiver, uint64(block.timestamp));
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
        owner = _ownerOf[id];
        if(owner == address(0)) revert NOT_MINTED();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
        interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function approve(address spender, uint256 id) public {
        revert NOT_ALLOWED();
    }

    function setApprovalForAll(address operator, bool approved) public {
        revert NOT_ALLOWED();
    }

    function transferFrom(address from,address to,uint256 id) public {
        revert NOT_ALLOWED();
    }

    function safeTransferFrom(address from,address to,uint256 id) public {
        revert NOT_ALLOWED();
    }

    function safeTransferFrom(address from, address to, uint256 id,bytes calldata data) public {
        revert NOT_ALLOWED();
    }

    function _getFlowRate(address token, address sender, address receiver) internal view returns(int96 flowRate) {
        (,flowRate,,) = cfaV1.getFlow(ISuperToken(token), sender, receiver);
    }

    // ============= private interface =============

    function _mint(uint256 id, address token, address sender, address receiver, uint64 startDate) internal {
        if(receiver == address(0)) revert ZERO_ADDRESS();
        bytes32 reverseKey = keccak256(abi.encodePacked(
                token,
                sender,
                receiver
            ));
        if(_revertStreamToId[reverseKey] != 0) revert ALREADY_MINTED();
        if(_ownerOf[id] != address(0)) revert ALREADY_MINTED();
        _ownerOf[id] = receiver;
        _tokenCFAData[id] = StreamData(token, startDate, sender);
        _revertStreamToId[reverseKey] = id;
        emit Transfer(address(0), receiver, id);
    }

    function _burn(address token, address sender, address receiver) internal {
        bytes32 reverseKey = keccak256(abi.encodePacked(token, sender, receiver));
        uint256 id = _revertStreamToId[reverseKey];
        if(id == 0) revert NOT_MINTED();
        delete _ownerOf[id];
        delete _tokenCFAData[id];
        delete _revertStreamToId[reverseKey];
        emit Transfer(receiver, address(0), id);
    }

    // ============= TODO: ??? =============

    function mint(address token, address sender, address receiver)  public {
        int96 flowRate = _getFlowRate(token, sender, receiver);
        if(flowRate > 0) {
            _tokenIds++;
            _mint(_tokenIds, token, sender, receiver, uint64(block.timestamp));
        }
    }

    function burn(address token, address sender, address receiver) public {
        if(msg.sender != receiver) revert NOT_STREAM_USER();
        int96 flowRate = _getFlowRate(token, sender, receiver);
        if(flowRate == 0) {
            _burn(token, sender, receiver);
        }
    }

    function setUrl(string memory _url) external {
        url = _url;
    }
}