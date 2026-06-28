using System.Windows;
using System.Windows.Threading;

namespace FA506IV.FTPMFix.Gui;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        DispatcherUnhandledException += OnDispatcherUnhandledException;
        AppDomain.CurrentDomain.UnhandledException += (_, args) =>
        {
            if (args.ExceptionObject is Exception ex)
            {
                ShowFatal(ex);
            }
        };

        base.OnStartup(e);
    }

    private void OnDispatcherUnhandledException(object sender, DispatcherUnhandledExceptionEventArgs e)
    {
        ShowFatal(e.Exception);
        e.Handled = true;
        Shutdown(-1);
    }

    private static void ShowFatal(Exception ex)
    {
        MessageBox.Show(
            ex.Message + (ex.InnerException is not null ? "\n\n" + ex.InnerException.Message : string.Empty),
            "FA506IV fTPM Fix — startup error",
            MessageBoxButton.OK,
            MessageBoxImage.Error);
    }
}