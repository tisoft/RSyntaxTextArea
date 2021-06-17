/*
 * 09/20/2008
 *
 * MakefileTokenMaker.java - Scanner for makefiles.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * LICENSE file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import java.util.Stack;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for makefiles.<p>
 *
 * This implementation was created using
 * <a href="http://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>, so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated <code>MakefileTokenMaker.java</code> file will contain two
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 * @author Robert Futrell
 * @version 0.5
 *
 */
%%

%public
%class MakefileTokenMaker
%extends AbstractJFlexTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{

	private Stack<Boolean> varDepths;


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public MakefileTokenMaker() {
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *                    occurs.
	 */
	@Override
	public void addToken(char[] array, int start, int end, int tokenType, int startOffset) {
		super.addToken(array, start,end, tokenType, startOffset);
		zzStartRead = zzMarkedPos;
	}


	/**
	 * {@inheritDoc}
	 */
	@Override
	public String[] getLineCommentStartAndEnd(int languageIndex) {
		return new String[] { "#", null };
	}


	/**
	 * Returns whether tokens of the specified type should have "mark
	 * occurrences" enabled for the current programming language.
	 *
	 * @param type The token type.
	 * @return Whether tokens of this type should have "mark occurrences"
	 *         enabled.
	 */
	public boolean getMarkOccurrencesOfTokenType(int type) {
		return type==Token.IDENTIFIER || type==Token.VARIABLE;
	}


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *        <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		s = text;
		try {
			yyreset(zzReader);
			yybegin(Token.NULL);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new TokenImpl();
		}

	}


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 */
	private boolean zzRefill() {
		return zzCurrentPos>=s.offset+s.count;
	}


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream 
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream 
	 */
	public final void yyreset(Reader reader) {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = zzPushbackPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}

Letter					= [A-Za-z]
Digit					= [0-9]
IdentifierStart			= ({Letter}|[_\.])
IdentifierPart			= ({IdentifierStart}|{Digit})
Identifier				= ({IdentifierStart}{IdentifierPart}*)
Label					= ({Identifier}":")

CurlyVarStart			= ("${")
ParenVarStart			= ("$(")

LineTerminator			= (\n)
WhiteSpace				= ([ \t\f])

UnclosedCharLiteral		= ([\']([^\'\n]|"\\'")*)
CharLiteral				= ({UnclosedCharLiteral}"'")
UnclosedStringLiteral	= ([\"]([^\"\n]|"\\\"")*)
StringLiteral			= ({UnclosedStringLiteral}[\"])
UnclosedBacktickLiteral	= ([\`]([^\`\n]|"\\`")*)
BacktickLiteral			= ({UnclosedBacktickLiteral}"`")

LineCommentBegin		= "#"

IntegerLiteral			= ({Digit}+)

Operator				= ([\:\+\?]?"=")


%state VAR

%%

<YYINITIAL> {

	/* Keywords */
	"addprefix" |
	"addsuffix" |
	"basename" |
	"dir" |
	"filter" |
	"filter-out" |
	"findstring" |
	"firstword" |
	"foreach" |
	"join" |
	"notdir" |
	"origin" |
	"pathsubst" |
	"shell" |
	"sort" |
	"strip" |
	"suffix" |
	"wildcard" |
	"word" |
	"words" |
	"ifeq" |
	"ifneq" |
	"else" |
	"endif" |
	"define" |
	"endef" |
	"ifdef" |
	"ifndef"					{ addToken(Token.RESERVED_WORD); }

	{LineTerminator}				{ addNullToken(); return firstToken; }

	{Label}							{ addToken(Token.PREPROCESSOR); }
	{Identifier}					{ addToken(Token.IDENTIFIER); }

	{WhiteSpace}+					{ addToken(Token.WHITESPACE); }

	/* String/Character literals. */
	{CharLiteral}					{ addToken(Token.LITERAL_CHAR); }
	{UnclosedCharLiteral}			{ addToken(Token.ERROR_CHAR); addNullToken(); return firstToken; }
	{StringLiteral}					{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{UnclosedStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	{BacktickLiteral}				{ addToken(Token.LITERAL_BACKQUOTE); }
	{BacktickLiteral}				{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }

	/* Variables. */
	{CurlyVarStart}					{ if (varDepths==null) { varDepths = new Stack<>(); } else { varDepths.clear(); } varDepths.push(Boolean.TRUE); start = zzMarkedPos-2; yybegin(VAR); }
	{ParenVarStart}					{ if (varDepths==null) { varDepths = new Stack<>(); } else { varDepths.clear(); } varDepths.push(Boolean.FALSE); start = zzMarkedPos-2; yybegin(VAR); }

	/* Comment literals. */
	{LineCommentBegin}.*			{ addToken(Token.COMMENT_EOL); addNullToken(); return firstToken; }

	/* Operators. */
	{Operator}					{ addToken(Token.OPERATOR); }

	/* Numbers */
	{IntegerLiteral}				{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>						{ addNullToken(); return firstToken; }

	/* Catch-all for anything else. */
	.							{ addToken(Token.IDENTIFIER); }

}

<VAR> {
	[^\}\)\$\#]+		{}
	"}"					{
							if (!varDepths.empty() && Boolean.TRUE.equals(varDepths.peek())) {
								varDepths.pop();
								if (varDepths.empty()) {
									addToken(start,zzStartRead, Token.VARIABLE); yybegin(YYINITIAL);
								}
							}
						}
	")"					{
							if (!varDepths.empty() && Boolean.FALSE.equals(varDepths.peek())) {
								varDepths.pop();
								if (varDepths.empty()) {
									addToken(start,zzStartRead, Token.VARIABLE); yybegin(YYINITIAL);
								}
							}
						}
	"${"				{ varDepths.push(Boolean.TRUE); }
	"$("				{ varDepths.push(Boolean.FALSE); }
	"$"					{}
	"#".*				{ int temp1 = zzStartRead; int temp2 = zzMarkedPos; addToken(start,zzStartRead-1, Token.VARIABLE); addToken(temp1, temp2-1, Token.COMMENT_EOL); addNullToken(); return firstToken; }
	<<EOF>>				{ addToken(start,zzStartRead-1, Token.VARIABLE); addNullToken(); return firstToken; }
}
