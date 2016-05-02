#  -----------------------------------------------------------------------
#  Copyright (c) Joerg Desch <github@jdesch.de>
#  -----------------------------------------------------------------------
#  PROJECT.: Header Extractor
#  REVISION: 0.3
#  LICENSE:  LGPL 2.1
#  -----------------------------------------------------------------------
#
#  This script extract all data types and constants defined in a ASCII
#  specification (like LaTeX or Markdown). The result is a C include file, which
#  must be included in the project source. Going this way ensures, that the
#  header always conforms to the protocol specs!
#
#  USAGE:
#
#    awk -v include_fname="APCOMMANDS" -f extract-c-source.awk sample.md > sample.h
#
#  DOCUMENTATION FILE:
#
#  All comments processed by this script must start with "%%". To get this
#  work with Pandoc/Markdown, just wrap these lines with HTML comments.
#
#  This script can handle "#define" and "struct" declarations. All structure
#  declarations where the name starts with a "PKT" are than put into a
#  union called "T_PACKET_DATA". In this case, a native byte array is added
#  to this union too. This byte array allows the direct / raw access to the
#  overlayed data packages. Note: if we have a define with the maximum packet
#  size called MAX_PACKET_DATA, we use it as size of the byte array. If not,
#  we use a single byte and the user must handle the boundaries. ;-)
#
#  Each comment line starting with "%% C-define#" is handled as C define. Each
#  comment line starting with "%% C-struct#" is handled as C struct declaration.
#  It is important that the whole declaration must be within one line!
#
#  The following example declares two defines and two structures. One of these
#  structures is a packet declaration and is added to an special union.
#  ,-----------------------------------------------------
#  |%% C-define# TEST             123
#  |%% C-define# FOO              "123"
#  |%% C-define# MAX_PACKET_DATA  10
#  |%% C-struct# FOOTYPE { uint8_t cmd; }
#  |%% C-struct# PKT_FOO { uint8_t cmd; uint16_t parm; }
#  `-----------------------------------------------------
#
#  Here is the (stripped down) output of the above file. Since MAX_PACKET_DATA
#  is declared, the union has an element bytes[] with the specified size.
#  ,-----------------------------------------------------
#  |#ifndef __APCOMMANDS_H__
#  |#define __APCOMMANDS_H__ 1
#  |
#  |#define TEST             123
#  |#define FOO              "123"
#  |#define MAX_PACKET_DATA  10
#  |
#  |#ifdef __GNUC__
#  |#define ___PACKED __attribute__((__packed__))
#  |#else
#  |#define ___PACKED
#  |#endif
#  |
#  |typedef struct ___PACKED tagFOOTYPE { uint8_t cmd; } T_FOOTYPE;
#  |typedef struct ___PACKED tagPKT_FOO { uint8_t cmd; uint16_t parm; } T_PKT_FOO;
#  |
#  |typedef union ___PACKED tagPACKET_DATA {
#  |    T_PKT_FOO foo;
#  |    uint8_t bytes[MAX_PACKET_DATA];
#  |} T_PACKET_DATA;
#  |
#  |#endif
#  `-----------------------------------------------------
#
#
#  =======================================================================


#  -----------------------------------------------------------------------
BEGIN{
  FS="#";                          # so we get the meta-comment, and it's data!
  cnt_defines=0;                   # number of defines
  cnt_structs=0;                   # number of structures
  a_define[0]=0;
  a_struct[0]=0;
  a_sname[0]=0;
  if ( length(include_fname) == 0 )
  {
    include_fname="COMMANDS";
  }
}

#  -----------------------------------------------------------------------
END{
  if ( cnt_defines<1  && cnt_structs<1 ) {
    printf("/* SORRY, NOTHING TO EXTRACT! */\n");
    exit 1;
  }

  print("/* -*- Mode: C -*-");
  print(" *");
  print(" * this file is generated from the documentation source by extract-c-source.awk!");
  print(" */\n\n");
  printf("#ifndef __%s_H__\n",include_fname);
  printf("#define __%s_H__ 1\n\n",include_fname);
  printf("#include <stdint.h>\n\n");

  have_max_packet_size=0;
  if ( cnt_defines > 0 ) {
    print("\n/* DEFINES\n */\n");
    for ( i=0; i<cnt_defines; i++ ){
      printf "#define %s\n",a_define[i];
      if ( match(a_define[i],"^MAX_PACKET_DATA") > 0 ) {
        have_max_packet_size=1;
      }
    }
    print "\n";
  }
  if ( cnt_structs > 0 ) {
    printf("#ifdef __GNUC__\n#define ___PACKED __attribute__((__packed__))\n");
    printf("#else\n#define ___PACKED\n#endif\n\n");
    print("/* STRUCT DECLARATIONS\n */\n");
    cnt_cmd_pkt=0;
    for ( i=0; i<cnt_structs; i++ ){
      printf "typedef struct ___PACKED tag%s %s T_%s;\n",a_sname[i],a_struct[i],a_sname[i];
      if ( match(a_sname[i],"^PKT") > 0 ) {
        a_pkt_union[cnt_cmd_pkt]=a_sname[i];
        cnt_cmd_pkt++;
      }
    }
    print "\n";
    if ( cnt_cmd_pkt > 0 ){
      printf("/* UNION OF ALL %d PAKETDATA TYPES\n */\n",cnt_cmd_pkt);
      printf "typedef union ___PACKED tagPACKET_DATA {\n";
      for ( i=0; i<cnt_cmd_pkt; i++ ){
        match(a_pkt_union[i],"^PKT_");
        tmp=substr(a_pkt_union[i],RLENGTH+1)
        printf "    T_%s %s;\n",a_pkt_union[i],tolower(tmp);
      }
      # if we have a define with the maximum packet size, lets use it. If not,
      # we use a byte and the user must handle the boundaries.
      if ( have_max_packet_size>0 ) {
        printf "    uint8 bytes[MAX_PACKET_DATA];\n";
      }else{
        printf "    uint8 bytes[1];\n";
      }
      printf "} T_PACKET_DATA;\n";
    }
  }
  print "\n#endif";
  print "/* =====[end of generated file]===== */\n";
  exit 0;
}

#  -----------------------------------------------------------------------
/^%% C-struct#/{
  #printf "c-struct= `%s'\n", $2

  # split into paket-name and structure
  #
  match($2,"^ ?[A-Za-z0-9_]+");              # everty field starts with a identifier.
  if ( RSTART > 0 ){
    if ( RLENGTH > 1 ){
      tmp=substr($2,1,RLENGTH);              # the name of the struct
      if ( substr(tmp,1,1)==" " )            # starts with a blank?
        s_name=substr(tmp,2);                # skip leading blank
      else                                   # else
        s_name=tmp;                          # use it `as is'

      tmp=substr($2,RLENGTH+1);              # the struct data
      if ( substr(tmp,1,1)==" " )            # starts with a blank?
        s_data=substr(tmp,2);                # skip leading blank
      else                                   # else
        s_data=tmp;                          # use it `as is'
#      printf "s_name=`%s' s_data=`%s'\n",s_name,s_data;
      # create the structure- and type declaration.
      a_struct[cnt_structs]=s_data;
      a_sname[cnt_structs]=s_name;
      cnt_structs++;
    }
  } else {
    printf "error: illegal C-struct entry `%s'\n",$2;
    exit 2;
  }
}

#  -----------------------------------------------------------------------
/^%% C-define#/{
  #printf "c-define= `%s'\n", $2

  if ( substr($2,1,1)==" " )                 # starts with a blank?
    a_define[cnt_defines]=substr($2,2);      # skip leading blank
  else                                       # else
    a_define[cnt_defines]=tmp;               # use it `as is'

  # if we have the RCS revision string, extract the id!!
  #
  if ( index(a_define[cnt_defines],"$Revision")>0 ){         # the right field?
    match($0,"[0-9]+\.[0-9]+");                              # check for a rev id
    if ( RSTART > 0 ){                                       # yes, we have on
      revision=substr($0,RSTART,RLENGTH);                    # extract it
      a_define[cnt_defines]=sprintf("PROTOCOL_SPEC_REV \"%s\"",revision);
    }
  }
  cnt_defines++;
}


# --[end of file]-----------------------------------------------------------
