enum PluginAppleEventCodes {
	ASPluginAppClassCode = 'exPM',
	ASPluginForCode = 'foR_',
	ASPluginWithCode = 'wITh',
	
	// Event codes
	ASPluginPropertyEventCode = 'Xprp',
	ASPluginTitleEventCode = 'Xtit',
	ASPluginEnableEventCode = 'Xena',
	ASPluginPerformEventCode = 'Xprf',
};


#define ASCodify(x) [NSNumber numberWithUnsignedLong:x]