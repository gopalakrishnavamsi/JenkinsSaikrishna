/**
 * Interface for envelope recipient resolution.
 */
public interface RecipientResolver {
	/**
	 * Tests whether recipients can be resolved by the source SObject type.
	 *
	 * @param sObjectType The SObject type name.
	 *
	 * @return True if this implementation can resolve recipients from the source SObject type, false otherwise.
	 */
	Boolean canResolveRecipients(String sObjectType);

	/**
	 * Tests whether recipient SObjects can be searched.
	 *
	 * @param sObjectType The SObject type name.
	 *
	 * @return True if this implementation can search the recipient SObject.
	 */
	Boolean canSearchRecipients(String sObjectType);

	/**
	 * Reads recipients from SObjects.
	 *
	 * @param sObjectType The SObject type name.
	 * @param sObjectIds The source SObject IDs.
	 *
	 * @return The resolved recipients.
	 */
	List<Recipient> getRecipients(String sObjectType, Set<Id> sObjectIds);

	/**
	 * Retrieves a list of recipients by name.
	 *
	 * @param sObjectType The SObject type name.
	 * @param name The name to search.
	 * @param behavior How the search is performed.
	 *
	 * @return The recipients matching the search criteria.
	 */
	List<Recipient> searchRecipients(String sObjectType, String name, SearchBehavior behavior);
}
