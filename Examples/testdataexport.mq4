
// EA code

#property strict

int file_handle;
string InpFileName = _Symbol + ".txt"; // File name
input string InpDirectoryName = "Data"; // Folder name

int OnInit()
{
	ResetLastError();
	file_handle = FileOpen(InpDirectoryName + "//" + InpFileName, FILE_SHARE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);
	if(file_handle == INVALID_HANDLE) {
		PrintFormat("Failed to open %s file, Error code = %d", InpFileName, GetLastError());
		ExpertRemove();
	}
	return INIT_SUCCEEDED;
}

void OnTick()
{
	// Datetime), Bid, Volume
	string s = TimeToStr(TimeGMT()) + " " + Bid + " " + Volume[0];
	FileWriteString(file_handle, s + "\r\n");
	FileFlush(file_handle);
}

void OnDeinit(const int reason)
{
	FileClose(file_handle);
}
