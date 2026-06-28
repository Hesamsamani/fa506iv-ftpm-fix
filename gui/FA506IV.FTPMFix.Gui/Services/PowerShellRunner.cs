using System.Diagnostics;
using System.Text;

namespace FA506IV.FTPMFix.Gui.Services;

public sealed class PowerShellRunner
{
    public async Task<ProcessResult> RunScriptAsync(
        string scriptPath,
        IEnumerable<string>? arguments = null,
        CancellationToken cancellationToken = default)
    {
        var args = new StringBuilder();
        args.Append("-NoProfile -ExecutionPolicy Bypass -File \"");
        args.Append(scriptPath);
        args.Append('"');
        if (arguments is not null)
        {
            foreach (var arg in arguments)
            {
                args.Append(' ');
                if (arg.StartsWith('-') || string.IsNullOrWhiteSpace(arg))
                {
                    args.Append(arg);
                }
                else
                {
                    args.Append('"').Append(arg.Replace("\"", "`\"")).Append('"');
                }
            }
        }

        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = args.ToString(),
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8,
        };

        using var process = new Process { StartInfo = psi, EnableRaisingEvents = true };
        var stdout = new StringBuilder();
        var stderr = new StringBuilder();

        process.OutputDataReceived += (_, e) => { if (e.Data is not null) stdout.AppendLine(e.Data); };
        process.ErrorDataReceived += (_, e) => { if (e.Data is not null) stderr.AppendLine(e.Data); };

        process.Start();
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();

        await process.WaitForExitAsync(cancellationToken);

        return new ProcessResult(process.ExitCode, stdout.ToString(), stderr.ToString());
    }
}

public readonly record struct ProcessResult(int ExitCode, string StdOut, string StdErr)
{
    public bool Success => ExitCode == 0;
}