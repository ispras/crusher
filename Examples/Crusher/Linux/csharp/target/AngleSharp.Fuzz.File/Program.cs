using System;
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
					var html = File.ReadAllText(args[0]);
					new HtmlParser().ParseDocument(html);
				}
				catch (InvalidOperationException) { }
			});
		}
	}
}
