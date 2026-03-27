// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BaseProofRegistry {
    struct Asset {
        bytes32 assetId;
        bytes32 canonicalHash;
        bytes32 rootAssetId;
        bytes32 parentAssetId;
        string metadataURI;
        address registrant;
        uint256 createdAt;
        bool revoked;
        bool exists;
    }

    struct License {
        bytes32 licenseId;
        bytes32 assetId;
        address licensee;
        string termsURI;
        uint256 createdAt;
    }

    address public owner;
    bool public paused;

    mapping(address => bool) public operators;
    mapping(bytes32 => Asset) public assets;
    mapping(bytes32 => bool) public canonicalHashUsed;
    mapping(bytes32 => bytes32[]) public childrenByParent;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorUpdated(address indexed operator, bool allowed);
    event PauseStatusChanged(bool isPaused);
    event AssetRegistered(
        bytes32 indexed assetId,
        bytes32 indexed canonicalHash,
        bytes32 indexed rootAssetId,
        bytes32 parentAssetId,
        address registrant,
        string metadataURI
    );
    event AssetOwnershipTransferred(
        bytes32 indexed assetId,
        address indexed previousRegistrant,
        address indexed newRegistrant
    );
    event AssetURIUpdated(
        bytes32 indexed assetId,
        string previousMetadataURI,
        string newMetadataURI
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || operators[msg.sender], "Not admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Registry paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function setOperator(address operator, bool allowed) external onlyOwner {
        require(operator != address(0), "Zero address");
        operators[operator] = allowed;
        emit OperatorUpdated(operator, allowed);
    }

    function setPaused(bool _paused) external onlyOwner {
        require(paused != _paused, "Already set");
        paused = _paused;
        emit PauseStatusChanged(_paused);
    }

    function registerOriginal(
        bytes32 assetId,
        bytes32 canonicalHash,
        string calldata metadataURI
    ) external onlyAdmin whenNotPaused {
        require(bytes(metadataURI).length > 0, "Empty metadata URI");
        _validateOriginalRegistration(assetId, canonicalHash, metadataURI);

        assets[assetId] = Asset({
            assetId: assetId,
            canonicalHash: canonicalHash,
            rootAssetId: assetId,
            parentAssetId: bytes32(0),
            metadataURI: metadataURI,
            registrant: msg.sender,
            createdAt: block.timestamp,
            revoked: false,
            exists: true
        });

        canonicalHashUsed[canonicalHash] = true;

        emit AssetRegistered(
            assetId,
            canonicalHash,
            assetId,
            bytes32(0),
            msg.sender,
            metadataURI
        );
    }

    function registerDerivative(
        bytes32 assetId,
        bytes32 canonicalHash,
        bytes32 parentAssetId,
        string calldata metadataURI
    ) external onlyAdmin whenNotPaused {
        require(bytes(metadataURI).length > 0, "Empty metadata URI");
        bytes32 rootAssetId = _validateDerivativeRegistration(
            assetId,
            canonicalHash,
            parentAssetId,
            metadataURI
        );

        assets[assetId] = Asset({
            assetId: assetId,
            canonicalHash: canonicalHash,
            rootAssetId: rootAssetId,
            parentAssetId: parentAssetId,
            metadataURI: metadataURI,
            registrant: msg.sender,
            createdAt: block.timestamp,
            revoked: false,
            exists: true
        });

        canonicalHashUsed[canonicalHash] = true;
        childrenByParent[parentAssetId].push(assetId);

        emit AssetRegistered(
            assetId,
            canonicalHash,
            rootAssetId,
            parentAssetId,
            msg.sender,
            metadataURI
        );
    }

    function transferAssetOwnership(bytes32 assetId, address newRegistrant)
        external
        whenNotPaused
    {
        require(assetId != bytes32(0), "Invalid assetId");
        require(newRegistrant != address(0), "Zero address");

        Asset storage asset = _getMutableAsset(assetId);

        require(
            msg.sender == asset.registrant ||
                msg.sender == owner ||
                operators[msg.sender],
            "Not authorized"
        );
        require(asset.registrant != newRegistrant, "Already registrant");

        address previousRegistrant = asset.registrant;
        asset.registrant = newRegistrant;

        emit AssetOwnershipTransferred(assetId, previousRegistrant, newRegistrant);
    }

    function updateAssetURI(bytes32 assetId, string calldata newMetadataURI)
        external
        whenNotPaused
    {
        require(assetId != bytes32(0), "Invalid assetId");
        require(bytes(newMetadataURI).length > 0, "Empty metadata URI");

        Asset storage asset = _getMutableAsset(assetId);

        require(
            msg.sender == asset.registrant ||
                msg.sender == owner ||
                operators[msg.sender],
            "Not authorized"
        );
        require(
            keccak256(bytes(asset.metadataURI)) != keccak256(bytes(newMetadataURI)),
            "Metadata URI unchanged"
        );

        string memory previousMetadataURI = asset.metadataURI;
        asset.metadataURI = newMetadataURI;

        emit AssetURIUpdated(assetId, previousMetadataURI, newMetadataURI);
    }

    function _validateOriginalRegistration(
        bytes32 assetId,
        bytes32 canonicalHash,
        string calldata metadataURI
    ) internal view {
        require(assetId != bytes32(0), "Invalid assetId");
        require(canonicalHash != bytes32(0), "Invalid canonical hash");
        require(bytes(metadataURI).length > 0, "Empty metadata URI");
        require(!assets[assetId].exists, "Asset already exists");
        require(!canonicalHashUsed[canonicalHash], "Canonical hash already used");
    }

    function _validateDerivativeRegistration(
        bytes32 assetId,
        bytes32 canonicalHash,
        bytes32 parentAssetId,
        string calldata metadataURI
    ) internal view returns (bytes32 rootAssetId) {
        require(assetId != bytes32(0), "Invalid assetId");
        require(canonicalHash != bytes32(0), "Invalid canonical hash");
        require(parentAssetId != bytes32(0), "Invalid parent assetId");
        require(bytes(metadataURI).length > 0, "Empty metadata URI");
        require(!assets[assetId].exists, "Asset already exists");
        require(!canonicalHashUsed[canonicalHash], "Canonical hash already used");
        require(assets[parentAssetId].exists, "Parent asset does not exist");
        require(!assets[parentAssetId].revoked, "Parent asset is revoked");

        rootAssetId = assets[parentAssetId].rootAssetId;
    }

    function _getMutableAsset(bytes32 assetId) internal view returns (Asset storage asset) {
        require(assets[assetId].exists, "Asset does not exist");
        require(!assets[assetId].revoked, "Asset is revoked");
        asset = assets[assetId];
    }

    function isCanonicalHashUsed(bytes32 canonicalHash) external view returns (bool) {
        return canonicalHashUsed[canonicalHash];
    }

    function getAssetLineage(bytes32 assetId) external view returns (bytes32 rootAssetId, bytes32 parentAssetId) {
        require(assets[assetId].exists, "Asset does not exist");
        Asset memory asset = assets[assetId];
        return (asset.rootAssetId, asset.parentAssetId);
    }

    function getAsset(bytes32 assetId)
        external
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            string memory,
            address,
            uint256
        )
    {
        require(assets[assetId].exists, "Asset does not exist");
        Asset memory asset = assets[assetId];

        return (
            asset.assetId,
            asset.canonicalHash,
            asset.rootAssetId,
            asset.parentAssetId,
            asset.metadataURI,
            asset.registrant,
            asset.createdAt
        );
    }
}
