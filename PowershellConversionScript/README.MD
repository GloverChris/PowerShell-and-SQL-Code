# How to Use

## Requires Powershell -version 2


  ### DESCRIPTION
    This script demonstrates how to write a Windows service in pure PowerShell.
    It dynamically generates a small PSService.exe wrapper, that in turn
    invokes this PowerShell script again for its start and stop events.

  ### PARAMETER Start
    Start the service.

  ### PARAMETER Stop
    Stop the service.

  ### PARAMETER Restart
    Stop then restart the service.

  ### PARAMETER Status
    Get the current service status: Not installed / Stopped / Running

  ### PARAMETER Setup
    Install the service.
    Optionally use the -Credential or -UserName arguments to specify the user
    account for running the service. By default, uses the LocalSystem account.
    Known limitation with the old PowerShell v2: It is necessary to use -Credential
    or -UserName. For example, use -UserName LocalSystem to emulate the v3+ default.

  ### PARAMETER Credential
    User and password credential to use for running the service.
    For use with the -Setup command.
    Generate a PSCredential variable with the Get-Credential command.

  ### PARAMETER UserName
    User account to use for running the service.
    For use with the -Setup command, in the absence of a Credential variable.
    The user must have the "Log on as a service" right. To give him that right,
    open the Local Security Policy management console, go to the
    "\Security Settings\Local Policies\User Rights Assignments" folder, and edit
    the "Log on as a service" policy there.
    Services should always run using a user account which has the least amount
    of privileges necessary to do its job.
    Three accounts are special, and do not require a password:
    * LocalSystem - The default if no user is specified. Highly privileged.
    * LocalService - Very few privileges, lowest security risk.
      Apparently not enough privileges for running PowerShell. Do not use.
    * NetworkService - Idem, plus network access. Same problems as LocalService.

  ### PARAMETER Password
    Password for UserName. If not specified, you will be prompted for it.
    It is strongly recommended NOT to use that argument, as that password is
    visible on the console, and in the task manager list.
    Instead, use the -UserName argument alone, and wait for the prompt;
    or, even better, use the -Credential argument.

  ### PARAMETER Remove
    Uninstall the service.

  ### PARAMETER Service
    Run the service in the background. Used internally by the script.
    Do not use, except for test purposes.

  ### PARAMETER SCMStart
    Process Service Control Manager start requests. Used internally by the script.
    Do not use, except for test purposes.

  ### PARAMETER SCMStop
    Process Service Control Manager stop requests. Used internally by the script.
    Do not use, except for test purposes.

  ### PARAMETER Control
    Send a control message to the service thread.

  ### PARAMETER Version
    Display this script version and exit.

  ## EXAMPLE
    # Setup the service and run it for the first time
    C:\PS>.\PSService.ps1 -Status
    Not installed
    C:\PS>.\PSService.ps1 -Setup
    C:\PS># At this stage, a copy of PSService.ps1 is present in the path
    C:\PS>PSService -Status
    Stopped
    C:\PS>PSService -Start
    C:\PS>PSService -Status
    Running
    C:\PS># Load the log file in Notepad.exe for review
    C:\PS>notepad ${ENV:windir}\Logs\PSService.log

  ## EXAMPLE
    # Stop the service and uninstall it.
    C:\PS>PSService -Stop
    C:\PS>PSService -Status
    Stopped
    C:\PS>PSService -Remove
    C:\PS># At this stage, no copy of PSService.ps1 is present in the path anymore
    C:\PS>.\PSService.ps1 -Status
    Not installed

  ## EXAMPLE
    # Configure the service to run as a different user
    C:\PS>$cred = Get-Credential -UserName LAB\Assistant
    C:\PS>.\PSService -Setup -Credential $cred

  ## EXAMPLE
    # Send a control message to the service, and verify that it received it.
    C:\PS>PSService -Control Hello
    C:\PS>Notepad C:\Windows\Logs\PSService.log
    # The last lines should contain a trace of the reception of this Hello message
