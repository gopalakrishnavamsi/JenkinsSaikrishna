/**
 * Interface for envelope document resolution.
 */
public interface DocumentResolver {

	/**
	 * Tests whether a document SObject type can be resolved by this implementation.
	 *
	 * @param type The document SObject type.
	 *
	 * @return True if this implementation can resolve the SObject type, false otherwise.
	 */
	Boolean canResolveDocuments(SObjectType type);

	/**
	 * Retrieves a list of documents by ID.
	 *
	 * @param type The document SObject type.
	 * @param documentIds The document SObject IDs.
	 *
	 * @return The resolved documents.
	 */
	List<Document> getDocuments(SObjectType type, Set<Id> documentIds);

	/**
	 *  Retrieves a filtered list of linked documents by parent ID.
	 *
	 * @param type The document SObject type.
	 * @param linkedEntityIds The linked SObject IDs.
	 * @param filter Optional query filter to apply.
	 *
	 * @return The documents linked to the Salesforce entities.
	 */
	List<Document> getLinkedDocuments(SObjectType type, Set<Id> linkedEntityIds, Query.Filter filter);

	/**
	 * Retrieves document folders for the specified type.
	 *
	 * @param type The document SObject type.
	 *
	 * @return The document folders.
	 */
	List<Document.Folder> getDocumentFolders(SObjectType type);

	/**
	 * Retrieves folder documents.
	 *
	 * @param type The document SObject type.
	 * @param folderIds The document folder IDs.
	 *
	 * @return The resolved documents in the folders.
	 */
	List<Document> getFolderDocuments(SObjectType type, Set<Id> folderIds);

	/**
	 * Gets the bytes of a resolvable document.
	 *
	 * @param type The document SObject type.
	 * @param documentIds The document SObject IDs.
	 *
	 * @return The resolved document bytes.
	 */
	Map<Id, Blob> getDocumentContent(SObjectType type, Set<Id> documentIds);
}
