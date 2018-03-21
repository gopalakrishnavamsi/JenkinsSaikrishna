/**
 * Interface for envelope document resolution.
 */
public interface DocumentResolver {

	/**
	 * Tests whether a document SObject type can be resolved by this implementation.
	 *
	 * @param sObjectType The SObject type name.
	 *
	 * @return True if this implementation can resolve the SObject type, false otherwise.
	 */
	Boolean canResolve(String sObjectType);

	/**
	 * Resolves an SObject to a document.
	 *
	 * @param sObjectType The SObject type name.
	 * @param sObjectId The SObject ID.
	 *
	 * @return The resolved document.
	 */
	Document resolve(String sObjectType, Id sObjectId);

	/**
	 * Gets the bytes of a resolvable document.
	 *
	 * @param sObjectType The SObject type name.
	 * @param sObjectId The SObject ID.
	 *
	 * @return The resolved document bytes.
	 */
	Blob getBytes(String sObjectType, Id sObjectId);
}
