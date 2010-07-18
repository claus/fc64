package components
{
	internal class ROMEmbeds
	{
		[Embed( source="/assets/kernal.901227-03.bin", mimeType="application/octet-stream" )]
		public static const KERNEL:Class;
		
		[Embed( source="/assets/basic.901226-01.bin", mimeType="application/octet-stream" )]
		public static const BASIC:Class;
		
		[Embed( source="/assets/characters.901225-01.bin", mimeType="application/octet-stream" )]
		public static const CHAR:Class;
	}
}

