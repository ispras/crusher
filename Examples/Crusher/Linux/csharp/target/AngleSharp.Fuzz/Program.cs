using AngleSharp.Html.Parser;
using AngleSharp;
using SharpFuzz;

namespace AngleSharp.Fuzz
{
	public class Program
	{
		public static void Main(string[] args)
		{
			Fuzzer.OutOfProcess.Run(stream =>
			{
				try
				{
					new HtmlParser().ParseDocument(stream);	
				}
				catch (InvalidOperationException) { }
			});
		}
	}
}
