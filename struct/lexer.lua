--[[pod_format="raw",created="2025-04-30 17:25:08",modified="2025-05-05 07:06:56",revision=17]]


--- Lexer
-- Provides an interface for lexing using
-- integer token types.
-- @module Lexer

require("class")

---@alias		token_type	integer
---@enum		token_type
local token_type = {
	-- special
	EOF          	= 0,       -- end of file/input
	BACKSLASH    	= 1 << 00, -- \

	-- alphanumeric
	ALPHA        	= 1 << 01, -- letters
	NUMERIC      	= 1 << 02, -- digits 0-9

	UNDERSCORE   	= 1 << 03, -- _

	-- whitespace
	SPACE        	= 1 << 04, -- ' '
	TAB          	= 1 << 05, -- \t
	NEWLINE      	= 1 << 06, -- \n

	-- operators
	EXCLAMATION		= 1 << 07, -- !
	PLUS			= 1 << 08, -- +
	DASH			= 1 << 09, -- -
	ASTERISK		= 1 << 10, -- *
	FORWARD_SLASH	= 1 << 11, -- /
	COLON			= 1 << 12, -- :
	SEMICOLON		= 1 << 13, -- ;
	COMMA			= 1 << 14, -- ,
	DOT				= 1 << 15, -- .
	QUESTION_MARK	= 1 << 16, -- ?
	CARET			= 1 << 17, -- ^
	TILDE			= 1 << 18, -- ~
	GRAVE			= 1 << 19, -- `
	BAR				= 1 << 20, -- |
	AT_SIGN			= 1 << 21, -- @
	OCTOTHORPE		= 1 << 22, -- #
	DOLLAR_SIGN		= 1 << 23, -- $
	PERCENT			= 1 << 24, -- %
	AMPERSAND		= 1 << 25, -- &

	-- grouping
	SINGLE_QUOTE  	= 1 << 26, -- '
	DOUBLE_QUOTE  	= 1 << 27, -- "
	OPEN_PAREN		= 1 << 28, -- (
	CLOSE_PAREN		= 1 << 29, -- )
	OPEN_BRACKET	= 1 << 30, -- [
	CLOSE_BRACKET	= 1 << 31, -- ]
	OPEN_BRACE		= 1 << 32, -- {
	CLOSE_BRACE		= 1 << 33, -- }
	OPEN_ANGLE		= 1 << 34, -- <
	CLOSE_ANGLE		= 1 << 35, -- >

	-- fallthrough
	SYMBOL       	= 1 << 36, -- any other single-character symbol

	-- error, maybe?
	UNKNOWN      	= 1 << 37  -- unrecognized character
}

local START_MAX = 32767
local LENGTH_MAX = 127

local TYPE_OFFSET = 0
local START_OFFSET = 40
local LENGTH_OFFSET = 56

-- how each token is represented in memory in the userdata matrix
local token_mask = {
	TYPE 		= 0x0000003fffffffff, -- 38 bits
	UNUSED		= 0x000000e000000000, -- 2 unused bits

	START		= 0x007fff0000000000, -- max 32767 for small, max 8 for big
	-- bool: start is larger than its max value, so use use it as the number
	-- of extra bytes used.
	START_BIG	= 0x0080000000000000,

	LENGTH		= 0x7f00000000000000, -- max 127 for small, max 8 for big
	-- bool: start is larger than its max value, so use use it as the number
	-- of extra bytes used.
	LENGTH_BIG	= 0x8000000000000000
}

-- Reverse mapping from integer to name
local token_type_names = {} -- : { [token_type]: string }
for name, id in pairs(token_type) do
	token_type_names[id] = name
end

-- number of trailing zeroes
function t0(val)
	if val == 0 then return 64 end
	local n, x = 0, val
	if (x & 0xffffffff)	== 0 then n, x 		= n+32, x >> 32 	end
	if (x & 0xffff)		== 0 then n, x 		= n+16, x >> 16 	end
	if (x & 0xff)			== 0 then n, x 		= n+8,  x >> 8  	end
	if (x & 0xf)			== 0 then n, x 		= n+4,  x >> 4  	end
	if (x & 0x3)			== 0 then n, x 		= n+2,  x >> 2  	end
	if (x & 0x1)			== 0 then n 			= n+1 				end
	return n
end

-- number of leading zeroes
function l0(val)
	if val == 0 then return 64 end
	local n, x = 0, val
	if (x >> 0x20) == 0 then n, x 	= n+32, x << 32 	end
	if (x >> 0x30) == 0 then n, x 	= n+16, x << 16 	end
	if (x >> 0x38) == 0 then n, x 	= n+8,  x << 8 	end
	if (x >> 0x3c) == 0 then n, x 	= n+4,  x << 4 	end
	if (x >> 0x3e) == 0 then n, x 	= n+2,  x << 2 	end
	if (x >> 0x3f) == 0 then n 		= n+1 				end
	return n
end


---@class token					Effectively a typed string view/slice
---									into the source.
-- @field lexer		lex		The lexer that this describes a slice of
-- @field integer	index			The index into the token buffer that this
-- 									resides in
-- @field integer	token_type	Token type
-- @field any		repr			Literal value (if applicable)
-- 									(corresponds to the type described
-- 									by token_type)
-- @field number	line			Current line number
-- @field number	col			Current column number
local token = class("token")
token.__index = token

function token:init(lex, index, repr, start)
	assert(l0(repr) >= l0(token_mask.TYPE), "repr has too large a value!")
	assert(l0(start) >= l0(token_mask.START >> START_OFFSET))
	self.lex:require_size(index)

	self.lex = lex
	self.index = index

	local value = 0
	if start > START_MAX then
		value = value | token_mask.START_BIG
		self.lex:require_size(index + 1)
		value = start << 32
		self.lex.cursor = self.lex.cursor + 1
	else
		value = start << START_OFFSET
	end

	value = value | repr
	self.lex.tokens:set(self.index, value)
end

-- @class lexer				The construct for lexing source into
-- 								tokens for parsing
-- @field source	userdata	A zero-indexed C-side array of u8 with
-- 								size N, where N is the length of the
-- 								source string
-- @field tokens	userdata	A zero-indexed C-side array of i64 with
-- 								size N, where N is the length of the
-- 								token buffer (dynamically sized)
-- @field cursor	number	Current index in source
-- @field line 	number	Current line number
-- @field col		number	Current column number
local lexer = class("lexer")
lexer.__index = lexer

--- Create a new lexer instance.
-- @param string source	Input string to lex
-- @return lexer	new instance
function lexer.init(source)
	self.source = userdata("u8", #source)
	self.source:row(0):set(0, string.byte(source, 1, -1))
	self.tokens = userdata("i64", #source)
	
	self.cursor = 0
	self.line = 1
	self.col = 1
end

function lexer:grow_tokbuf()
	local cur_size = self.tokens:width()
	local new_buf = userdata("i64", cur_size * 2)
	self.tokens:blit(new_buf, 0, 0, 0, 0, cur_size)
	self.tokens = new_buf
end

function lexer:require_size(size)
	while self.tokens:width() < size do
		self:grow_tokbuf()
	end
end

--- Return the current character without advancing.
-- @return integer? character or nil if at end
function lexer:peek() end

--- Return the current character and then advance to
--- the next character.
-- @return integer? character or nil if at end
function lexer:pop() end

--- Check if a character is numeric (0-9).
-- @tparam string ch	Single character
-- @treturn boolean	true if digit
function token:is_numeric()
	return (self.repr & token_type.NUMERIC) > 0
end

--- Check if a character is alphabetic (A-Z, a-z).
-- @tparam string ch	Single character
-- @treturn boolean	true if alpha
function token:is_alpha()
	return (self.repr & token_type.ALPHA) > 0
end

--- Check if a character is alphanumeric or underscore.
-- @tparam string ch	Single character
-- @treturn boolean	true if alphanumeric
function token:is_alphanumeric()
	return (self.repr & (token_type.ALPHA | token_type.NUMERIC)) > 0
end

--- Lex a sequence of alphabetic characters.
-- @treturn token	alpha token
function lexer:lex_alpha() end

--- Peek the current character without consuming it.
-- @treturn token? character or nil if at end
function lexer:peek_token() end

--- Produce the next token from the source.
-- @treturn token	next token
function lexer:pop_token() end

return {
	lexer = lexer,
	token_type = token_type,
	token_type_names = token_type_names,
}

