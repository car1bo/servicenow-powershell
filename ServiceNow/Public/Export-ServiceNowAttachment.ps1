Function Export-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Save a ServiceNow attachment identified by its sys_id property and saved as the filename specified.

    .DESCRIPTION
    Save a ServiceNow attachment identified by its sys_id property and saved as the filename specified.

    .PARAMETER SysID
    The ServiceNow sys_id of the file

    .PARAMETER FileName
    File name the file is saved as.  Do not include the path.

    .PARAMETER Destination
    Path the file is saved to.  Do not include the file name.

    .PARAMETER AllowOverwrite
    Allows the function to overwrite the existing file.

    .PARAMETER AppendNameWithSysID
    Adds the SysID to the file name.  Intended for use when a ticket has multiple files with the same name.

    .EXAMPLE
    Export-ServiceNowAttachment -SysID $SysID -FileName 'mynewfile.txt'

    Save the attachment with the specified sys_id with a name of 'mynewfile.txt'

    .EXAMPLE
    Get-ServiceNowAttachment -Id INC1234567 | Export-ServiceNowAttachment

    Save all attachments from the ticket.  Filenames will be assigned from the attachment name.

    .EXAMPLE
    Get-ServiceNowAttachment -Id INC1234567 | Export-ServiceNowAttachment -AppendNameWithSysID

    Save all attachments from the ticket.  Filenames will be assigned from the attachment name and appended with the sys_id.

    .EXAMPLE
    Get-ServiceNowAttachment -Id INC1234567 | Export-ServiceNowAttachment -Destination $path -AllowOverwrite

    Save all attachments from the ticket to the destination allowing for overwriting the destination file.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess = $true)]
    Param(
        
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('file_name')]
        [string] $FileName,

        # Out path to download files
        [parameter()]
        [ValidateScript( {
                Test-Path $_
            })]
        [string] $Destination = $PWD.Path,

        # Options impacting downloads
        [parameter()]
        [switch] $AllowOverwrite,

        # Options impacting downloads
        [parameter()]
        [switch] $AppendNameWithSysId,

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName = 'Automation', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Hashtable] $Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {
        $authParams = Get-ServiceNowAuth -C $Connection -S $ServiceNowSession
    }

    process	{

        $params = $authParams.Clone()

        $params.Uri += '/attachment/' + $SysId + '/file'

        $thisFileName = $FileName
        If ( $AppendNameWithSysId.IsPresent ) {
            $thisFileName = "{0}_{1}{2}" -f [io.path]::GetFileNameWithoutExtension($thisFileName), $SysId, [io.path]::GetExtension($thisFileName)
        }
        $outFile = Join-Path $Destination $thisFileName

        If ((Test-Path $outFile) -and -not $AllowOverwrite.IsPresent) {
            throw ('The file ''{0}'' already exists.  Please choose a different name, use the -AppendNameWithSysID switch parameter, or use the -AllowOverwrite switch parameter to overwrite the file.' -f $OutFile)
        }

        $params.OutFile = $outFile

        If ($PSCmdlet.ShouldProcess($outFile, "Save attachment")) {
            Invoke-WebRequest @params
        }
    }
    end {}
}
