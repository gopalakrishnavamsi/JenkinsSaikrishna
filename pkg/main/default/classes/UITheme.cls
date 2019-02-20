public class UITheme {
	public enum Theme {
		Classic, Lightning, Salesforce1, Other
	}

	private static Theme currentThemeInternal;

	private static Theme getTheme() {
		if (currentThemeInternal == null) {
			setTheme(UserInfo.getUiThemeDisplayed());
		}
		return currentThemeInternal;
	}

	@TestVisible
	private static void setTheme(final String t) {
		if (t == 'Theme1' || t == 'Theme2' || t == 'Theme3') {
			currentThemeInternal = Theme.Classic;
		} else if (t == 'Theme4d') {
			currentThemeInternal = Theme.Lightning;
		} else if (t == 'Theme4t') {
			currentThemeInternal = Theme.Salesforce1;
		} else {
			currentThemeInternal = Theme.Other;
		}
	}

	public static Theme currentTheme {
		get {
			return getTheme();
		}
	}

	public static Boolean isClassic {
		get {
			// Salesforce reports the theme as Classic on community sites, but treats as Lightning/SF1 otherwise.
			return getTheme() == Theme.Classic && !Salesforce.isCommunitySite;
		}
	}

	public static Boolean isLightning {
		get {
			return getTheme() == Theme.Lightning;
		}
	}

	public static Boolean isSalesforce1 {
		get {
			return getTheme() == Theme.Salesforce1;
		}
	}
}