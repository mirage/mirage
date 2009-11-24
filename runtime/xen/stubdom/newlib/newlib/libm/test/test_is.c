#include "test.h"
#include <ctype.h>

int setascii;
int setlower;
int setupper;
int myascii;
int mycntrl;
int myspace;
int myprint;
int myalnum;
int mydigit;
int myxdigit;
int myalpha;
int myupper;
int mylower;
int mygraph;
int mypunct;

void
_DEFUN(test_is_single,(i),
       int i)
{
  setascii = 0;
  setlower = 0;
  setupper = 0;

  myascii = 0;
  mycntrl = 0;
  myspace = 0;
  myprint = 0;
  myalnum = 0;
  mydigit = 0;
  myxdigit = 0;
  myalpha = 0;
  myupper = 0;
  mylower = 0;
  mygraph = 0;
  mypunct = 0;

  switch (i) {
    case 0000:
      myascii = 1;
      mycntrl = 1;
      setascii = 0;
      setlower = 0;
      setupper = 0;
      break;
    case 0001:
      myascii = 1;
      mycntrl = 1;
      setascii = 1;
      setlower = 1;
      setupper = 1;
      break;
    case 0002:
      myascii = 1;
      mycntrl = 1;
      setascii = 2;
      setlower = 2;
      setupper = 2;
      break;
    case 0003:
      myascii = 1;
      mycntrl = 1;
      setascii = 3;
      setlower = 3;
      setupper = 3;
      break;
    case 0004:
      myascii = 1;
      mycntrl = 1;
      setascii = 4;
      setlower = 4;
      setupper = 4;
      break;
    case 0005:
      myascii = 1;
      mycntrl = 1;
      setascii = 5;
      setlower = 5;
      setupper = 5;
      break;
    case 0006:
      myascii = 1;
      mycntrl = 1;
      setascii = 6;
      setlower = 6;
      setupper = 6;
      break;
    case 0007:
      myascii = 1;
      mycntrl = 1;
      setascii = 7;
      setlower = 7;
      setupper = 7;
      break;
    case 0010:
      myascii = 1;
      mycntrl = 1;
      setascii = 8;
      setlower = 8;
      setupper = 8;
      break;
    case 0011:
      myascii = 1;
      mycntrl = 1;
      myspace = 1;
      setascii = 9;
      setlower = 9;
      setupper = 9;
      break;
    case 0012:
      myascii = 1;
      mycntrl = 1;
      myspace = 1;
      setascii = 10;
      setlower = 10;
      setupper = 10;
      break;
    case 0013:
      myascii = 1;
      mycntrl = 1;
      myspace = 1;
      setascii = 11;
      setlower = 11;
      setupper = 11;
      break;
    case 0014:
      myascii = 1;
      mycntrl = 1;
      myspace = 1;
      setascii = 12;
      setlower = 12;
      setupper = 12;
      break;
    case 0015:
      myascii = 1;
      mycntrl = 1;
      myspace = 1;
      setascii = 13;
      setlower = 13;
      setupper = 13;
      break;
    case 0016:
      myascii = 1;
      mycntrl = 1;
      setascii = 14;
      setlower = 14;
      setupper = 14;
      break;
    case 0017:
      myascii = 1;
      mycntrl = 1;
      setascii = 15;
      setlower = 15;
      setupper = 15;
      break;
    case 0020:
      myascii = 1;
      mycntrl = 1;
      setascii = 16;
      setlower = 16;
      setupper = 16;
      break;
    case 0021:
      myascii = 1;
      mycntrl = 1;
      setascii = 17;
      setlower = 17;
      setupper = 17;
      break;
    case 0022:
      myascii = 1;
      mycntrl = 1;
      setascii = 18;
      setlower = 18;
      setupper = 18;
      break;
    case 0023:
      myascii = 1;
      mycntrl = 1;
      setascii = 19;
      setlower = 19;
      setupper = 19;
      break;
    case 0024:
      myascii = 1;
      mycntrl = 1;
      setascii = 20;
      setlower = 20;
      setupper = 20;
      break;
    case 0025:
      myascii = 1;
      mycntrl = 1;
      setascii = 21;
      setlower = 21;
      setupper = 21;
      break;
    case 0026:
      myascii = 1;
      mycntrl = 1;
      setascii = 22;
      setlower = 22;
      setupper = 22;
      break;
    case 0027:
      myascii = 1;
      mycntrl = 1;
      setascii = 23;
      setlower = 23;
      setupper = 23;
      break;
    case 0030:
      myascii = 1;
      mycntrl = 1;
      setascii = 24;
      setlower = 24;
      setupper = 24;
      break;
    case 0031:
      myascii = 1;
      mycntrl = 1;
      setascii = 25;
      setlower = 25;
      setupper = 25;
      break;
    case 0032:
      myascii = 1;
      mycntrl = 1;
      setascii = 26;
      setlower = 26;
      setupper = 26;
      break;
    case 0033:
      myascii = 1;
      mycntrl = 1;
      setascii = 27;
      setlower = 27;
      setupper = 27;
      break;
    case 0034:
      myascii = 1;
      mycntrl = 1;
      setascii = 28;
      setlower = 28;
      setupper = 28;
      break;
    case 0035:
      myascii = 1;
      mycntrl = 1;
      setascii = 29;
      setlower = 29;
      setupper = 29;
      break;
    case 0036:
      myascii = 1;
      mycntrl = 1;
      setascii = 30;
      setlower = 30;
      setupper = 30;
      break;
    case 0037:
      myascii = 1;
      mycntrl = 1;
      setascii = 31;
      setlower = 31;
      setupper = 31;
      break;
    case ' ':
      myascii = 1;
      myprint = 1;
      myspace = 1;
      setascii = 32;
      setlower = 32;
      setupper = 32;
      break;
    case '!':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 33;
      setlower = 33;
      setupper = 33;
      break;
    case '"':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 34;
      setlower = 34;
      setupper = 34;
      break;
    case '#':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 35;
      setlower = 35;
      setupper = 35;
      break;
    case '$':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 36;
      setlower = 36;
      setupper = 36;
      break;
    case '%':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 37;
      setlower = 37;
      setupper = 37;
      break;
    case '&':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 38;
      setlower = 38;
      setupper = 38;
      break;
    case '\'':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 39;
      setlower = 39;
      setupper = 39;
      break;
    case '\(':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 40;
      setlower = 40;
      setupper = 40;
      break;
    case ')':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 41;
      setlower = 41;
      setupper = 41;
      break;
    case '*':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 42;
      setlower = 42;
      setupper = 42;
      break;
    case '+':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 43;
      setlower = 43;
      setupper = 43;
      break;
    case ',':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 44;
      setlower = 44;
      setupper = 44;
      break;
    case '-':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 45;
      setlower = 45;
      setupper = 45;
      break;
    case '.':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 46;
      setlower = 46;
      setupper = 46;
      break;
    case '/':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 47;
      setlower = 47;
      setupper = 47;
      break;
    case '0':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 48;
      setlower = 48;
      setupper = 48;
      break;
    case '1':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 49;
      setlower = 49;
      setupper = 49;
      break;
    case '2':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 50;
      setlower = 50;
      setupper = 50;
      break;
    case '3':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 51;
      setlower = 51;
      setupper = 51;
      break;
    case '4':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 52;
      setlower = 52;
      setupper = 52;
      break;
    case '5':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 53;
      setlower = 53;
      setupper = 53;
      break;
    case '6':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 54;
      setlower = 54;
      setupper = 54;
      break;
    case '7':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 55;
      setlower = 55;
      setupper = 55;
      break;
    case '8':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 56;
      setlower = 56;
      setupper = 56;
      break;
    case '9':
      myalnum = 1;
      myascii = 1;
      mydigit = 1;
      mygraph = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 57;
      setlower = 57;
      setupper = 57;
      break;
    case ':':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 58;
      setlower = 58;
      setupper = 58;
      break;
    case ';':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 59;
      setlower = 59;
      setupper = 59;
      break;
    case '<':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 60;
      setlower = 60;
      setupper = 60;
      break;
    case '=':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 61;
      setlower = 61;
      setupper = 61;
      break;
    case '>':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 62;
      setlower = 62;
      setupper = 62;
      break;
    case '?':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 63;
      setlower = 63;
      setupper = 63;
      break;
    case '@':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 64;
      setlower = 64;
      setupper = 64;
      break;
    case 'A':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      myxdigit = 1;
      setascii = 65;
      setlower = 97;
      setupper = 65;
      break;
    case 'B':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      myxdigit = 1;
      setascii = 66;
      setlower = 98;
      setupper = 66;
      break;
    case 'C':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      myxdigit = 1;
      setascii = 67;
      setlower = 99;
      setupper = 67;
      break;
    case 'D':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      myxdigit = 1;
      setascii = 68;
      setlower = 100;
      setupper = 68;
      break;
    case 'E':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      myxdigit = 1;
      setascii = 69;
      setlower = 101;
      setupper = 69;
      break;
    case 'F':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      myxdigit = 1;
      setascii = 70;
      setlower = 102;
      setupper = 70;
      break;
    case 'G':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 71;
      setlower = 103;
      setupper = 71;
      break;
    case 'H':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 72;
      setlower = 104;
      setupper = 72;
      break;
    case 'I':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 73;
      setlower = 105;
      setupper = 73;
      break;
    case 'J':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 74;
      setlower = 106;
      setupper = 74;
      break;
    case 'K':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 75;
      setlower = 107;
      setupper = 75;
      break;
    case 'L':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 76;
      setlower = 108;
      setupper = 76;
      break;
    case 'M':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 77;
      setlower = 109;
      setupper = 77;
      break;
    case 'N':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 78;
      setlower = 110;
      setupper = 78;
      break;
    case 'O':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 79;
      setlower = 111;
      setupper = 79;
      break;
    case 'P':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 80;
      setlower = 112;
      setupper = 80;
      break;
    case 'Q':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 81;
      setlower = 113;
      setupper = 81;
      break;
    case 'R':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 82;
      setlower = 114;
      setupper = 82;
      break;
    case 'S':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 83;
      setlower = 115;
      setupper = 83;
      break;
    case 'T':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 84;
      setlower = 116;
      setupper = 84;
      break;
    case 'U':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 85;
      setlower = 117;
      setupper = 85;
      break;
    case 'V':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 86;
      setlower = 118;
      setupper = 86;
      break;
    case 'W':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 87;
      setlower = 119;
      setupper = 87;
      break;
    case 'X':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 88;
      setlower = 120;
      setupper = 88;
      break;
    case 'Y':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 89;
      setlower = 121;
      setupper = 89;
      break;
    case 'Z':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      myupper = 1;
      setascii = 90;
      setlower = 122;
      setupper = 90;
      break;
    case '[':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 91;
      setlower = 91;
      setupper = 91;
      break;
    case '\\':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 92;
      setlower = 92;
      setupper = 92;
      break;
    case ']':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 93;
      setlower = 93;
      setupper = 93;
      break;
    case '^':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 94;
      setlower = 94;
      setupper = 94;
      break;
    case '_':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 95;
      setlower = 95;
      setupper = 95;
      break;
    case '`':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 96;
      setlower = 96;
      setupper = 96;
      break;
    case 'a':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 97;
      setlower = 97;
      setupper = 65;
      break;
    case 'b':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 98;
      setlower = 98;
      setupper = 66;
      break;
    case 'c':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 99;
      setlower = 99;
      setupper = 67;
      break;
    case 'd':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 100;
      setlower = 100;
      setupper = 68;
      break;
    case 'e':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 101;
      setlower = 101;
      setupper = 69;
      break;
    case 'f':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      myxdigit = 1;
      setascii = 102;
      setlower = 102;
      setupper = 70;
      break;
    case 'g':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 103;
      setlower = 103;
      setupper = 71;
      break;
    case 'h':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 104;
      setlower = 104;
      setupper = 72;
      break;
    case 'i':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 105;
      setlower = 105;
      setupper = 73;
      break;
    case 'j':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 106;
      setlower = 106;
      setupper = 74;
      break;
    case 'k':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 107;
      setlower = 107;
      setupper = 75;
      break;
    case 'l':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 108;
      setlower = 108;
      setupper = 76;
      break;
    case 'm':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 109;
      setlower = 109;
      setupper = 77;
      break;
    case 'n':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 110;
      setlower = 110;
      setupper = 78;
      break;
    case 'o':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 111;
      setlower = 111;
      setupper = 79;
      break;
    case 'p':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 112;
      setlower = 112;
      setupper = 80;
      break;
    case 'q':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 113;
      setlower = 113;
      setupper = 81;
      break;
    case 'r':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 114;
      setlower = 114;
      setupper = 82;
      break;
    case 's':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 115;
      setlower = 115;
      setupper = 83;
      break;
    case 't':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 116;
      setlower = 116;
      setupper = 84;
      break;
    case 'u':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 117;
      setlower = 117;
      setupper = 85;
      break;
    case 'v':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 118;
      setlower = 118;
      setupper = 86;
      break;
    case 'w':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 119;
      setlower = 119;
      setupper = 87;
      break;
    case 'x':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 120;
      setlower = 120;
      setupper = 88;
      break;
    case 'y':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 121;
      setlower = 121;
      setupper = 89;
      break;
    case 'z':
      myalnum = 1;
      myalpha = 1;
      myascii = 1;
      mygraph = 1;
      mylower = 1;
      myprint = 1;
      setascii = 122;
      setlower = 122;
      setupper = 90;
      break;
    case '{':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 123;
      setlower = 123;
      setupper = 123;
      break;
    case '|':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 124;
      setlower = 124;
      setupper = 124;
      break;
    case '}':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 125;
      setlower = 125;
      setupper = 125;
      break;
    case '~':
      myascii = 1;
      mygraph = 1;
      myprint = 1;
      mypunct = 1;
      setascii = 126;
      setlower = 126;
      setupper = 126;
      break;
    case 0177:
      myascii = 1;
      mycntrl = 1;
      setascii = 127;
      setlower = 127;
      setupper = 127;
      break;
    case 0200:
      setascii = 0;
      setlower = 128;
      setupper = 128;
      break;
    case 0201:
      setascii = 1;
      setlower = 129;
      setupper = 129;
      break;
    case 0202:
      setascii = 2;
      setlower = 130;
      setupper = 130;
      break;
    case 0203:
      setascii = 3;
      setlower = 131;
      setupper = 131;
      break;
    case 0204:
      setascii = 4;
      setlower = 132;
      setupper = 132;
      break;
    case 0205:
      setascii = 5;
      setlower = 133;
      setupper = 133;
      break;
    case 0206:
      setascii = 6;
      setlower = 134;
      setupper = 134;
      break;
    case 0207:
      setascii = 7;
      setlower = 135;
      setupper = 135;
      break;
    case 0210:
      setascii = 8;
      setlower = 136;
      setupper = 136;
      break;
    case 0211:
      setascii = 9;
      setlower = 137;
      setupper = 137;
      break;
    case 0212:
      setascii = 10;
      setlower = 138;
      setupper = 138;
      break;
    case 0213:
      setascii = 11;
      setlower = 139;
      setupper = 139;
      break;
    case 0214:
      setascii = 12;
      setlower = 140;
      setupper = 140;
      break;
    case 0215:
      setascii = 13;
      setlower = 141;
      setupper = 141;
      break;
    case 0216:
      setascii = 14;
      setlower = 142;
      setupper = 142;
      break;
    case 0217:
      setascii = 15;
      setlower = 143;
      setupper = 143;
      break;
    case 0220:
      setascii = 16;
      setlower = 144;
      setupper = 144;
      break;
    case 0221:
      setascii = 17;
      setlower = 145;
      setupper = 145;
      break;
    case 0222:
      setascii = 18;
      setlower = 146;
      setupper = 146;
      break;
    case 0223:
      setascii = 19;
      setlower = 147;
      setupper = 147;
      break;
    case 0224:
      setascii = 20;
      setlower = 148;
      setupper = 148;
      break;
    case 0225:
      setascii = 21;
      setlower = 149;
      setupper = 149;
      break;
    case 0226:
      setascii = 22;
      setlower = 150;
      setupper = 150;
      break;
    case 0227:
      setascii = 23;
      setlower = 151;
      setupper = 151;
      break;
    case 0230:
      setascii = 24;
      setlower = 152;
      setupper = 152;
      break;
    case 0231:
      setascii = 25;
      setlower = 153;
      setupper = 153;
      break;
    case 0232:
      setascii = 26;
      setlower = 154;
      setupper = 154;
      break;
    case 0233:
      setascii = 27;
      setlower = 155;
      setupper = 155;
      break;
    case 0234:
      setascii = 28;
      setlower = 156;
      setupper = 156;
      break;
    case 0235:
      setascii = 29;
      setlower = 157;
      setupper = 157;
      break;
    case 0236:
      setascii = 30;
      setlower = 158;
      setupper = 158;
      break;
    case 0237:
      setascii = 31;
      setlower = 159;
      setupper = 159;
      break;
    case 0240:
      setascii = 32;
      setlower = 160;
      setupper = 160;
      break;
    case 0241:
      setascii = 33;
      setlower = 161;
      setupper = 161;
      break;
    case 0242:
      setascii = 34;
      setlower = 162;
      setupper = 162;
      break;
    case 0243:
      setascii = 35;
      setlower = 163;
      setupper = 163;
      break;
    case 0244:
      setascii = 36;
      setlower = 164;
      setupper = 164;
      break;
    case 0245:
      setascii = 37;
      setlower = 165;
      setupper = 165;
      break;
    case 0246:
      setascii = 38;
      setlower = 166;
      setupper = 166;
      break;
    case 0247:
      setascii = 39;
      setlower = 167;
      setupper = 167;
      break;
    case 0250:
      setascii = 40;
      setlower = 168;
      setupper = 168;
      break;
    case 0251:
      setascii = 41;
      setlower = 169;
      setupper = 169;
      break;
    case 0252:
      setascii = 42;
      setlower = 170;
      setupper = 170;
      break;
    case 0253:
      setascii = 43;
      setlower = 171;
      setupper = 171;
      break;
    case 0254:
      setascii = 44;
      setlower = 172;
      setupper = 172;
      break;
    case 0255:
      setascii = 45;
      setlower = 173;
      setupper = 173;
      break;
    case 0256:
      setascii = 46;
      setlower = 174;
      setupper = 174;
      break;
    case 0257:
      setascii = 47;
      setlower = 175;
      setupper = 175;
      break;
    case 0260:
      setascii = 48;
      setlower = 176;
      setupper = 176;
      break;
    case 0261:
      setascii = 49;
      setlower = 177;
      setupper = 177;
      break;
    case 0262:
      setascii = 50;
      setlower = 178;
      setupper = 178;
      break;
    case 0263:
      setascii = 51;
      setlower = 179;
      setupper = 179;
      break;
    case 0264:
      setascii = 52;
      setlower = 180;
      setupper = 180;
      break;
    case 0265:
      setascii = 53;
      setlower = 181;
      setupper = 181;
      break;
    case 0266:
      setascii = 54;
      setlower = 182;
      setupper = 182;
      break;
    case 0267:
      setascii = 55;
      setlower = 183;
      setupper = 183;
      break;
    case 0270:
      setascii = 56;
      setlower = 184;
      setupper = 184;
      break;
    case 0271:
      setascii = 57;
      setlower = 185;
      setupper = 185;
      break;
    case 0272:
      setascii = 58;
      setlower = 186;
      setupper = 186;
      break;
    case 0273:
      setascii = 59;
      setlower = 187;
      setupper = 187;
      break;
    case 0274:
      setascii = 60;
      setlower = 188;
      setupper = 188;
      break;
    case 0275:
      setascii = 61;
      setlower = 189;
      setupper = 189;
      break;
    case 0276:
      setascii = 62;
      setlower = 190;
      setupper = 190;
      break;
    case 0277:
      setascii = 63;
      setlower = 191;
      setupper = 191;
      break;
    case 0300:
      setascii = 64;
      setlower = 192;
      setupper = 192;
      break;
    case 0301:
      setascii = 65;
      setlower = 193;
      setupper = 193;
      break;
    case 0302:
      setascii = 66;
      setlower = 194;
      setupper = 194;
      break;
    case 0303:
      setascii = 67;
      setlower = 195;
      setupper = 195;
      break;
    case 0304:
      setascii = 68;
      setlower = 196;
      setupper = 196;
      break;
    case 0305:
      setascii = 69;
      setlower = 197;
      setupper = 197;
      break;
    case 0306:
      setascii = 70;
      setlower = 198;
      setupper = 198;
      break;
    case 0307:
      setascii = 71;
      setlower = 199;
      setupper = 199;
      break;
    case 0310:
      setascii = 72;
      setlower = 200;
      setupper = 200;
      break;
    case 0311:
      setascii = 73;
      setlower = 201;
      setupper = 201;
      break;
    case 0312:
      setascii = 74;
      setlower = 202;
      setupper = 202;
      break;
    case 0313:
      setascii = 75;
      setlower = 203;
      setupper = 203;
      break;
    case 0314:
      setascii = 76;
      setlower = 204;
      setupper = 204;
      break;
    case 0315:
      setascii = 77;
      setlower = 205;
      setupper = 205;
      break;
    case 0316:
      setascii = 78;
      setlower = 206;
      setupper = 206;
      break;
    case 0317:
      setascii = 79;
      setlower = 207;
      setupper = 207;
      break;
    case 0320:
      setascii = 80;
      setlower = 208;
      setupper = 208;
      break;
    case 0321:
      setascii = 81;
      setlower = 209;
      setupper = 209;
      break;
    case 0322:
      setascii = 82;
      setlower = 210;
      setupper = 210;
      break;
    case 0323:
      setascii = 83;
      setlower = 211;
      setupper = 211;
      break;
    case 0324:
      setascii = 84;
      setlower = 212;
      setupper = 212;
      break;
    case 0325:
      setascii = 85;
      setlower = 213;
      setupper = 213;
      break;
    case 0326:
      setascii = 86;
      setlower = 214;
      setupper = 214;
      break;
    case 0327:
      setascii = 87;
      setlower = 215;
      setupper = 215;
      break;
    case 0330:
      setascii = 88;
      setlower = 216;
      setupper = 216;
      break;
    case 0331:
      setascii = 89;
      setlower = 217;
      setupper = 217;
      break;
    case 0332:
      setascii = 90;
      setlower = 218;
      setupper = 218;
      break;
    case 0333:
      setascii = 91;
      setlower = 219;
      setupper = 219;
      break;
    case 0334:
      setascii = 92;
      setlower = 220;
      setupper = 220;
      break;
    case 0335:
      setascii = 93;
      setlower = 221;
      setupper = 221;
      break;
    case 0336:
      setascii = 94;
      setlower = 222;
      setupper = 222;
      break;
    case 0337:
      setascii = 95;
      setlower = 223;
      setupper = 223;
      break;
    case 0340:
      setascii = 96;
      setlower = 224;
      setupper = 224;
      break;
    case 0341:
      setascii = 97;
      setlower = 225;
      setupper = 225;
      break;
    case 0342:
      setascii = 98;
      setlower = 226;
      setupper = 226;
      break;
    case 0343:
      setascii = 99;
      setlower = 227;
      setupper = 227;
      break;
    case 0344:
      setascii = 100;
      setlower = 228;
      setupper = 228;
      break;
    case 0345:
      setascii = 101;
      setlower = 229;
      setupper = 229;
      break;
    case 0346:
      setascii = 102;
      setlower = 230;
      setupper = 230;
      break;
    case 0347:
      setascii = 103;
      setlower = 231;
      setupper = 231;
      break;
    case 0350:
      setascii = 104;
      setlower = 232;
      setupper = 232;
      break;
    case 0351:
      setascii = 105;
      setlower = 233;
      setupper = 233;
      break;
    case 0352:
      setascii = 106;
      setlower = 234;
      setupper = 234;
      break;
    case 0353:
      setascii = 107;
      setlower = 235;
      setupper = 235;
      break;
    case 0354:
      setascii = 108;
      setlower = 236;
      setupper = 236;
      break;
    case 0355:
      setascii = 109;
      setlower = 237;
      setupper = 237;
      break;
    case 0356:
      setascii = 110;
      setlower = 238;
      setupper = 238;
      break;
    case 0357:
      setascii = 111;
      setlower = 239;
      setupper = 239;
      break;
    case 0360:
      setascii = 112;
      setlower = 240;
      setupper = 240;
      break;
    case 0361:
      setascii = 113;
      setlower = 241;
      setupper = 241;
      break;
    case 0362:
      setascii = 114;
      setlower = 242;
      setupper = 242;
      break;
    case 0363:
      setascii = 115;
      setlower = 243;
      setupper = 243;
      break;
    case 0364:
      setascii = 116;
      setlower = 244;
      setupper = 244;
      break;
    case 0365:
      setascii = 117;
      setlower = 245;
      setupper = 245;
      break;
    case 0366:
      setascii = 118;
      setlower = 246;
      setupper = 246;
      break;
    case 0367:
      setascii = 119;
      setlower = 247;
      setupper = 247;
      break;
    case 0370:
      setascii = 120;
      setlower = 248;
      setupper = 248;
      break;
    case 0371:
      setascii = 121;
      setlower = 249;
      setupper = 249;
      break;
    case 0372:
      setascii = 122;
      setlower = 250;
      setupper = 250;
      break;
    case 0373:
      setascii = 123;
      setlower = 251;
      setupper = 251;
      break;
    case 0374:
      setascii = 124;
      setlower = 252;
      setupper = 252;
      break;
    case 0375:
      setascii = 125;
      setlower = 253;
      setupper = 253;
      break;
    case 0376:
      setascii = 126;
      setlower = 254;
      setupper = 254;
      break;
    case 0377:
      setascii = 127;
      setlower = 255;
      setupper = 255;
      break;
    default:
      abort();
      
    }

}


int _DEFUN(def_isascii,(i), int i) { return isascii(i); }
int _DEFUN(def_iscntrl,(i), int i) { return iscntrl(i); }
int _DEFUN(def_isspace,(i), int i) { return isspace(i); }
int _DEFUN(def_isprint,(i), int i) { return isprint(i); }
int _DEFUN(def_isalnum,(i), int i) { return isalnum(i); }
int _DEFUN(def_isdigit,(i), int i) { return isdigit(i); }
int _DEFUN(def_isxdigit,(i), int i) { return isxdigit(i); }
int _DEFUN(def_isalpha,(i), int i) { return isalpha(i); }
int _DEFUN(def_isupper,(i), int i) { return isupper(i); }
int _DEFUN(def_islower,(i), int i) { return islower(i); }
int _DEFUN(def_isgraph,(i), int i) { return isgraph(i); }
int _DEFUN(def_ispunct,(i), int i) { return ispunct(i); }
int _DEFUN(def_tolower,(i), int i) { return tolower(i); }
int _DEFUN(def_toupper,(i), int i) { return toupper(i); }
int _DEFUN(def_toascii,(i), int i) { return toascii(i); }
int _DEFUN(def__tolower,(i), int i) { return _tolower(i); }
int _DEFUN(def__toupper,(i), int i) { return _toupper(i); }

extern int inacc;
void
_DEFUN(test_is_set,(func, name, p),
       int (*func)() _AND
       char *name _AND
       int *p)
{
  int i;
  newfunc(name);
  for (i = 0; i < 255; i++) {
    int r = func(i) != 0;
    line(i);
    test_is_single(i);
    if (*p  != r) 
      {
	printf("%s:%d wrong result, is %d shouldbe %d\n", name, i, r,*p);
	inacc++;
      }
  }
}
void
_DEFUN(test_to_set,(func, name, p, low, high),
       int (*func)() _AND
       char *name _AND
       int *p _AND
       int low _AND
       int high)
{
  int i;
  newfunc(name);
  for (i = low; i <= high; i++) {
    int r = func(i) ;
    line(i);
    test_is_single(i);
    if (*p  != r) 
      {
	printf("%s:%d wrong result, is %d shouldbe %d\n", name, i, r,*p);
	inacc++;
      }
  }
}


#undef isascii
#undef iscntrl
#undef isspace
#undef isprint
#undef isalnum
#undef isdigit
#undef isxdigit
#undef isalpha
#undef isupper
#undef islower
#undef isgraph
#undef ispunct
#undef tolower
#undef toupper
#undef toascii
#undef _tolower
#undef _toupper

void
_DEFUN_VOID(test_is)
{
  test_is_set(def_isalnum, "isalnum define", &myalnum);
  test_is_set(def_isalpha, "isalpha define", &myalpha);
  test_is_set(def_isascii, "isascii define", &myascii);
  test_is_set(def_iscntrl, "iscntrl define", &mycntrl);
  test_is_set(def_isdigit, "isdigit define", &mydigit);
  test_is_set(def_isgraph, "isgraph define", &mygraph);
  test_is_set(def_islower, "islower define", &mylower);
  test_is_set(def_isprint, "isprint define", &myprint);
  test_is_set(def_ispunct, "ispunct define", &mypunct);
  test_is_set(def_isspace, "isspace define", &myspace);
  test_is_set(def_isupper, "isupper define", &myupper);
  test_is_set(def_isxdigit, "isxdigit define", &myxdigit);
  test_is_set(isalnum, "isalnum function", &myalnum);
  test_is_set(isalpha, "isalpha function", &myalpha);
  test_is_set(isascii, "isascii function", &myascii);
  test_is_set(iscntrl, "iscntrl function", &mycntrl);
  test_is_set(isgraph, "isgraph function", &mygraph);
  test_is_set(islower, "islower function", &mylower);
  test_is_set(isprint, "isprint function", &myprint);
  test_is_set(ispunct, "ispunct function", &mypunct);
  test_is_set(isspace, "isspace function", &myspace);
  test_is_set(isupper, "isupper function", &myupper);
  test_is_set(isxdigit, "isxdigit function", &myxdigit);
  test_to_set(_tolower, "_tolower function", &setlower, 'A','Z');
  test_to_set(_toupper, "_toupper function", &setupper, 'a','z');
  test_to_set(def__tolower, "_tolower define", &setlower, 'A','Z');
  test_to_set(def__toupper, "_toupper define", &setupper, 'a','z');
  test_to_set(def_toascii, "toascii define", &setascii, 0,255);
  test_to_set(def_tolower, "tolower define", &setlower, 0,255);
  test_to_set(def_toupper, "toupper define", &setupper, 0,255);
  test_to_set(toascii, "toascii function", &setascii, 0,255);
  test_to_set(tolower, "tolower function", &setlower, 0,255);
  test_to_set(toupper, "toupper function", &setupper, 0,255);
}
