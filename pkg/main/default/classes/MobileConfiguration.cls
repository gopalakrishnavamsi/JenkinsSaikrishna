public with sharing class MobileConfiguration {

	private static MobileConfiguration self = null;

	public Device currentDevice { get; private set; }
	public Boolean isMobileTaggerEnabled { get; private set; }
	public Boolean showMobileTagger {
		get {
			return isMobileTaggerEnabled
				&& currentDevice.isSalesforce1Native
				&& (currentDevice.os != Device.OS.Other);
		}
	}
	public Boolean showIFrameTagger {
		get {
			return currentDevice.os == Device.OS.Other
				|| !currentDevice.isSalesforce1Native
				|| (!isMobileTaggerEnabled
				&& currentDevice.os == Device.OS.IOS
				&& currentDevice.type != Device.Type.Phone);
		}
	}
	public Boolean allowInPersonSigning {
		get {
			return !this.isMobileTaggerEnabled
				&& this.currentDevice.os == Device.OS.IOS
				&& this.currentDevice.type == Device.Type.Tablet;
		}
	}
	public String errorMessage { get; private set; }
	public Boolean isValid {
		get {
			return String.isBlank(this.errorMessage);
		}
	}

	@TestVisible
	private MobileConfiguration(
		final Device currentDevice,
		final Boolean isMobileTaggerEnabled,
		final String errorMessage) {

		this.currentDevice = currentDevice;
		this.isMobileTaggerEnabled = isMobileTaggerEnabled;
		this.errorMessage = errorMessage;
	}

	public static MobileConfiguration getInstance() {
		String userAgent = null;
		if (ApexPages.currentPage() != null) {
			userAgent = ApexPages.currentPage().getHeaders().get('User-Agent');
		}
		return getInstance(userAgent);
	}

	public static MobileConfiguration getInstance(final String userAgent) {
		if (self == null) {
			self = new MobileConfiguration(
				Device.fromUserAgent(userAgent),
				false,
				null);
		}
		return self;
	}
}
