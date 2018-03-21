/**
 * Interface for SObject entity resolution.
 */
public interface EntityResolver {

	/**
	 * Tests whether an SObject type can be resolved by this implementation.
	 *
	 * @param sObjectType The SObject type name.
	 *
	 * @return True if this implementation can resolve the SObject type, false otherwise.
	 */
	Boolean canResolve(String sObjectType);

	/**
	 * Resolves an SObject's label, name, and parent by ID.
	 *
	 * @param sObjectType The SObject type name.
	 * @param sObjectId The SObject ID.
	 *
	 * @return The resolved entity.
	 */
	Entity resolve(String sObjectType, Id sObjectId);
}
