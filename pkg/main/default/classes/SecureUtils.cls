/**
 * Created by fred.wade on 2018-12-19.
 */

public with sharing class SecureUtils {

	private static Blob encryptionKey;

	private static Blob getEncryptionKey() {
		if (encryptionKey == null) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			if (String.isBlank(s.EncryptionKey__c)) throw new DocuSignException(Label.KeyNotFound);
			encryptionKey = String.isBlank(s.EncryptionKey__c) ? null : EncodingUtil.base64Decode(s.EncryptionKey__c);
		}
		return encryptionKey;
	}

	/**
	 * Encrypts and base64 encodes a string.
	 *
	 * @param s The string to encrypt.
	 *
	 * @return The base64-encoded encrypted string.
	 */
	public static String encrypt(final String s) {
		if (s == null) return null;
		return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', getEncryptionKey(), Blob.valueOf(s)));
	}

	/**
	 * Decrypts a base64-encoded encrypted string.
	 *
	 * @param s The encrypted base64-encoded string.
	 *
	 * @return The decrypted string.
	 */
	public static String decrypt(final String s) {
		if (s == null) return null;
		return Crypto.decryptWithManagedIV('AES256', getEncryptionKey(), EncodingUtil.base64Decode(s)).toString();
	}
}
