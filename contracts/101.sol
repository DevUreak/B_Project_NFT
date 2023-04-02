// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract S20Idol is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    CountersUpgradeable.Counter private _tokenIdCounter;
    bool public isBurnable; // true 일때만 소각 가능 onlyowner 
    string private base; // 베이스 주소는 서버 이전고려?, onlyowner 
    bool public isUsingDefaultBaseURI;

    event SetBurnable(bool isBurnable);
    event DefaultBaseURIActivated();
    event BaseURIUpdated(string);

    constructor() {
        _disableInitializers();
    }
    // S20Idol : S2T
    function initialize(string memory name, string memory symbol) initializer public {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
    }


    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

    }


    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {
        super._burn(tokenId);
    }

    // 베이스 url 셋팅
    function setBaseURI(string memory _base) public onlyOwner {
        //require(keccak256(abi.encodePacked(factory.defaultBaseURI())) != keccak256(abi.encodePacked(_base)), "ERC721: wrong base URI");
        isUsingDefaultBaseURI = false;
        base = _base;
        emit BaseURIUpdated(_base);
    }

    // "" 값으로 초기화 
    function setDefaultBaseURI() public onlyOwner {
        isUsingDefaultBaseURI = true;
        base = "";
        emit DefaultBaseURIActivated();
    }


    /**  baseURI를 조회하는 함수
    * @return uri baseURI. baseURI는 반드시 '/' 로 끝나야함
    */
    function _baseURI() internal view override returns (string memory) {
        // 디폴트 url 주소 셋팅 해야함 
        return isUsingDefaultBaseURI ? "" : base;
    }

    /**  tokenURI를 조회하는 함수.
    * @param _tokenId 토큰 ID
    * @return uri tokenURI. tokenURI는 ${baseURI}${chainId}/${contract address}/${tokenId} 로 구성된다.
    * 컨트랙트 어드레스는 시즌마다 컨트랙트를 배포해서 시즌별로 nft 발행이되니 참고 바람 
    */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
                baseURI,
                block.chainid.toString(),
                '/',
                address(this).toHexString(),
                '/',
                _tokenId.toString()
            )
        ) : "";
    }


    //소각 상태와 양도 상태 체크
    function burn(uint256 _tokenId) public onlyAllowedOperator(ownerOf(_tokenId)) {
        require(isBurnable, "ERC721: not burnable");
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: caller is not token owner nor approved");
        _burn(_tokenId);
    }

    // 소각 설정
    function setBurnable(bool _isBurnable) public onlyOwner {
        isBurnable = _isBurnable;
    }

    /** 
    * contractURI를 조회하는 함수.
    * @return ${baseURI}${chainId}/${contract address} 로 구성
    */
    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(
                abi.encodePacked(
                    baseURI,
                    block.chainid.toString(),
                    '/',
                    address(this).toHexString()
                )
            ) : "";
    }


    // royal fee, base feature setting 
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    // ---- 오픈씨 로열티를 위한 modifier onlyAllowedOperatorApproval
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(_operator) {
        super.setApprovalForAll(_operator, _approved);
    }

    function approve(
        address _operator,
        uint256 _tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(_operator) {
        super.approve(_operator, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }
}