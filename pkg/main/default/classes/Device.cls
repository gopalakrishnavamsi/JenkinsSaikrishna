public class Device {

	private static final Pattern ANDROID_PHONE_REGEX = Pattern.compile('.*chrome/[.0-9]* mobile.*');

	public enum OS {
		IOS, Android, Other
	}

	public enum Type {
		Phone, Tablet, Other
	}

	public OS os { get; private set; }
	public Type type { get; private set; }
	public Boolean isMobile {
		get {
			return this.type == Device.Type.Phone || this.type == Device.Type.Tablet;
		}
	}
	public Boolean isSalesforce1Native { get; private set; }

	@TestVisible
	private Device(final OS os, final Type type, final Boolean isSalesforce1Native) {
		this.os = os;
		this.type = type;
		this.isSalesforce1Native = isSalesforce1Native;
	}

	public static Device fromUserAgent(final String userAgent) {
		Device result = null;

		if (String.isNotBlank(userAgent)) {
			String ua = userAgent.toLowerCase();
			Boolean isSalesforce1Native = ua.contains('salesforcetouchcontainer');
			if (ua.contains('iphone')) {
				result = new Device(OS.IOS, Type.Phone, isSalesforce1Native);
			} else if (ua.contains('ipad')) {
				result = new Device(OS.IOS, Type.Tablet, isSalesforce1Native);
			} else if (ua.contains('android')) {
				if (ANDROID_PHONE_REGEX.matcher(ua).matches()) {
					result = new Device(OS.Android, Type.Phone, isSalesforce1Native);
				} else {
					result = new Device(OS.Android, Type.Tablet, isSalesforce1Native);
				}
			}
		}

		if (result == null) {
			result = new Device(OS.Other, Type.Other, false);
		}
		return result;
	}
}