/**
 * Interface for envelope document resolution.
 */
public interface DocumentResolver {

	/**
	 * Tests whether a document SObject type can be resolved by this implementation.
	 *
	 * @param sObjectType The document SObject type name.
	 *
	 * @return True if this implementation can resolve the SObject type, false otherwise.
	 */
	Boolean canResolveDocument(String sObjectType);

	/**
	 * Resolves an SObject to a document.
	 *
	 * @param sObjectType The document SObject type name.
	 * @param sObjectIds The document SObject IDs.
	 *
	 * @return The resolved documents.
	 */
	List<Document> getDocuments(String sObjectType, Set<Id> sObjectIds);

	/**
	 * Retrieves document folders for the specified type.
	 *
	 * @param sObjectType The document SObject type name.
	 *
	 * @return
	 */
	List<Document.Folder> getDocumentFolders(String sObjectType);

	/**
	 * Retrieves folder documents.
	 *
	 * @param sObjectType The document SObject type name.
	 * @param folderIds The document folder IDs.
	 *
	 * @return The resolved documents in the folders.
	 */
	List<Document> getFolderDocuments(String sObjectType, Set<Id> folderIds);

	/**
	 * Gets the bytes of a resolvable document.
	 *
	 * @param sObjectType The document SObject type name.
	 * @param sObjectIds The document SObject IDs.
	 *
	 * @return The resolved document bytes.
	 */
	Map<Id, Blob> getDocumentContent(String sObjectType, Set<Id> sObjectIds);
}
