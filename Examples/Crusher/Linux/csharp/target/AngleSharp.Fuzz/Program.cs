using System;
using AngleSharp.Parser.Html;
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
					new HtmlParser().Parse(stream);	
				}
				catch (InvalidOperationException) { }
			});
		}
	}
}
