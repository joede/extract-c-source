# Source code extraction helper

This simple AWK script extract all data types and constants defined in a ASCII
specification (like LaTeX or Markdown). The result is a C include file, which
must be included in the project source. Going this way ensures, that the header
always conforms to the protocol specs!

The goal of this script is, that the user who writes the protocol documenation,
adds special comments in front of the description of the command. These
comments includes some C specific data types and constants, which belongs to
that command.

## In more detail

All comments processed by this script must start with "%%". To get this
work with Pandoc/Markdown, just wrap these lines with HTML comments.

This script can handle "#define" and "struct" declarations. All structure
declarations where the name starts with a "PKT" are than put into a
union called `T_PACKET_DATA`. In this case, a native byte array is added
to this union too. This byte array allows the direct (raw) access to the
overlayed data packages. **Note:** if we have a define with the maximum packet
size called `MAX_PACKET_DATA`, we use it as size of the byte array. If not,
we use a single byte and the user must handle the boundaries. ;-)

Each comment line starting with `%% C-define#` is handled as C define. Each
comment line starting with `%% C-struct#` is handled as C structure declaration.
It is important that the whole declaration must be within one line!

The following example declares two defines and two structures. One of these
structures is a packet declaration and is added to an special union.

~~~~
%% C-define# TEST             123
%% C-define# FOO              "123"
%% C-define# MAX_PACKET_DATA  10
%% C-struct# FOOTYPE { uint8_t cmd; }
%% C-struct# PKT_FOO { uint8_t cmd; uint16_t parm; }
~~~~

Here is the (stripped down) output of the above file. Since `MAX_PACKET_DATA`
is declared, the union has an element `bytes[]` with the specified size.

~~~~
#ifndef __APCOMMANDS_H__
#define __APCOMMANDS_H__ 1

#define TEST             123
#define FOO              "123"
#define MAX_PACKET_DATA  10

#ifdef __GNUC__
#define ___PACKED __attribute__((__packed__))
#else
#define ___PACKED
#endif

typedef struct ___PACKED tagFOOTYPE { uint8_t cmd; } T_FOOTYPE;
typedef struct ___PACKED tagPKT_FOO { uint8_t cmd; uint16_t parm; } T_PKT_FOO;

typedef union ___PACKED tagPACKET_DATA {
    T_PKT_FOO foo;
    uint8_t bytes[MAX_PACKET_DATA];
} T_PACKET_DATA;

#endif
~~~~


## License

LGPL 2.1

This library/tool is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.
