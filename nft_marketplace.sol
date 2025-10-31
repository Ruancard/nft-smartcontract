// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "hardhat/console.sol";

contract NFTMarketp1ace is ERC721, ERC721Enumerable{
    struct NFT {
        uint256 tokenId;
        string name;
        address owner;
        uint256 price;
        bool isForSale;
        string contentURI; // Campo para armazenar link/conteúdo do NFT
    }
    
    struct NFTForSale{
        uint256 tokenId;
        string name;
        uint256 price;
    }

    mapping(uint256 => NFT) private _nfts;
    mapping(uint256 => NFTForSale) private _NFTsForSale;

    // Array para manter registro de todos os tokenIds
    uint256[] private allTokenIds;
    
    // Contador de tokens
    uint256 private _tokenIdCounter;

    constructor() ERC721("nft_marketplace", "NFTM") {}

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function convertBoolToString(bool _input) internal pure returns (string memory) {
        if (_input) {
            return "true";
        } else {
            return "false";
        }
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    // Função atualizada para criar NFT com conteúdo
   function createNFT(
        string memory name,
        uint256 price,
        string memory contentURI
    ) public {
        uint256 tokenId = _tokenIdCounter;
        require(!_exists(tokenId), "ID de token ja existe");
        require(bytes(contentURI).length > 0, "URI do conteudo nao pode ser vazio");
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter++;
        _nfts[tokenId] = NFT(tokenId, name, msg.sender, price, false, contentURI);
        _NFTsForSale[tokenId] = NFTForSale(tokenId, name, price);
        allTokenIds.push(tokenId);
    }

    function toggleNFTForSale(uint256 tokenId) public {
        require(_exists(tokenId), "ID do token nao existe");
        require(ownerOf(tokenId) == msg.sender, "Voce nao e dono do token");
        if (_nfts[tokenId].isForSale) {
            _nfts[tokenId].isForSale = false;
        }
        else {
            _nfts[tokenId].isForSale = true;
        }
    }

    function buyNFT(uint256 tokenId) public payable {
        require(ownerOf(tokenId) != msg.sender, "Voce ja e dono do token");
        require(_exists(tokenId), "ID do token nao existe");
        require(_nfts[tokenId].isForSale, "Token nao esta para venda");
        require(msg.value >= _nfts[tokenId].price, "Saldo insuficiente");
        address payable seller = payable(ownerOf(tokenId));
        uint256 price = _nfts[tokenId].price;

        _transfer(seller, msg.sender, tokenId);

        _nfts[tokenId].isForSale = false;
        _nfts[tokenId].owner = msg.sender;

        (bool success, ) = seller.call{value: price}("");
        require(success, "Falha no envio de ether para o vendedor");

        if (msg.value > price) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - price}("");
            require(refundSuccess, "Falha na devolucao do troco");
        }
    }

    function getNFTPrice(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ID de token nao existe");
        uint256 price = _nfts[tokenId].price;
        return(price);
    }

    function getNFTsForSale() public view returns (NFTForSale[] memory) {
        // Primeiro, contamos quantas NFTs estão à venda
        uint256 forSaleCount = 0;
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            if (_nfts[allTokenIds[i]].isForSale) {
                forSaleCount++;
            }
        }
        // Criamos o array com o tamanho correto
        NFTForSale[] memory forSaleNFTs = new NFTForSale[](forSaleCount);
        uint256 currentIndex = 0;
        // Preenchemos o array apenas com NFTs à venda
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 tokenId = allTokenIds[i];
            if (_nfts[tokenId].isForSale){
                forSaleNFTs[currentIndex] = _NFTsForSale[tokenId];
                currentIndex++;
                }
            }
        return (forSaleNFTs);
    }

    function getMyNFTs() public view returns (NFT[] memory) {
    // Primeiro, contamos quantas NFTs são minhas
    uint256 myCount = 0;
    for (uint256 i = 0; i < allTokenIds.length; i++) {
        if (ownerOf(allTokenIds[i]) == msg.sender) {
            myCount++;
        }
    }
    // Criamos o array com o tamanho correto
    NFT[] memory myNFTs = new NFT[](myCount);
    uint256 currentIndex = 0;
    // Preenchemos o array apenas com as minhas NFTs
    for (uint256 i = 0; i < allTokenIds.length; i++) {
        uint256 tokenId = allTokenIds[i];
        if (ownerOf(tokenId) == msg.sender) {
            myNFTs[currentIndex] = NFT(
                _nfts[tokenId].tokenId,
                _nfts[tokenId].name,
                _nfts[tokenId].owner,
                _nfts[tokenId].price,
                _nfts[tokenId].isForSale,
                _nfts[tokenId].contentURI
            );
            currentIndex++;
        }
    }
    return myNFTs;
    }
}
