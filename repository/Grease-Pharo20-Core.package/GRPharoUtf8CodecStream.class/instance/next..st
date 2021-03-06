streaming
next: anInteger
	"Convert the given string from UTF-8 using the fast path if converting to Latin-1"
	| output byte1 byte2 byte3 byte4 unicode count alreadyWide |
	output := ByteString new: anInteger.
	count := 0.
	alreadyWide := false.
	[ count < anInteger and: [ stream atEnd not ] ] whileTrue: [
		byte1 := stream next.
		unicode := byte1.
		(byte1 bitAnd: 16rE0) = 192 ifTrue: [ "two bytes"
			byte2 := stream next.
			(byte2 bitAnd: 16rC0) = 16r80 ifFalse: [ self invalidUtf8 ].
			unicode := ((byte1 bitAnd: 31) bitShift: 6) + (byte2 bitAnd: 63) ].
		(byte1 bitAnd: 16rF0) = 224 ifTrue: [ "three bytes"
			byte2 := stream next.
			(byte2 bitAnd: 16rC0) = 16r80 ifFalse: [ self invalidUtf8 ].
			byte3 := stream next.
			(byte3 bitAnd: 16rC0) = 16r80 ifFalse: [ self invalidUtf8 ].
			unicode := ((byte1 bitAnd: 15) bitShift: 12) + ((byte2 bitAnd: 63) bitShift: 6)
				+ (byte3 bitAnd: 63).
			alreadyWide ifFalse: [
				output := WideString withAll: output.
				alreadyWide := true ] ].
		(byte1 bitAnd: 16rF8) = 240 ifTrue: [ "four bytes"
			byte2 := stream next.
			(byte2 bitAnd: 16rC0) = 16r80 ifFalse: [ self invalidUtf8 ].
			byte3 := stream next.
			(byte3 bitAnd: 16rC0) = 16r80 ifFalse: [ self invalidUtf8 ].
			byte4 := stream next.
			(byte4 bitAnd: 16rC0) = 16r80 ifFalse: [ self invalidUtf8 ].
			unicode := ((byte1 bitAnd: 16r7) bitShift: 18) +
							((byte2 bitAnd: 63) bitShift: 12) + 
							((byte3 bitAnd: 63) bitShift: 6) +
							(byte4 bitAnd: 63).
			alreadyWide ifFalse: [
				output := WideString withAll: output.
				alreadyWide := true ] ].
		unicode ifNil: [ self invalidUtf8 ].
		unicode = 16rFEFF "ignore BOM" ifFalse: [
			count := count + 1.
			output at: count put: (Character codePoint: unicode). ].
		unicode := nil ].
	^ count < anInteger
		ifTrue: [ output first: count ]
		ifFalse: [ output ]