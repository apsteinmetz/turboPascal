/* SPLIT; split a long text file into two pieces */


#include <stdio.h>
#include <io.h>
#include <stdlib.h>

const long bufsize = 4096; /* big buffer for file copy */

char *buf;

typedef char string[81];

/* ===================================================== */
int exist(char *path)
{
FILE *test;

  test = fopen(path,"r");
  if (test != NULL)
  {
	fclose(test);
	return(1);
  }
  else
	return(0);
}

/* ===================================================== */
char *MakeName(char *name, int count)

{
   string ToName, ext, cnt;
   int i = 0;

    strcpy(ToName,name);
    sprintf(cnt,"%d",count);
    if (count > 999)
    {
      puts("Max files is 999");
      exit(10);
    };
    ext[i++] = '.';
    if (count < 100)
	ext[i++] = '0';
    if (count <  10)
	ext[i++] = '0';
    ext[i] = '\0';
    strcat(ToName,ext);
    strcat(ToName,cnt);
    return (ToName);
}

/* =================================================== */
int ParseName(char *FromName, char *ToName1, char *ToName2)
{
  string 	drive, dir, name, ext;
  int		count = 0;

  fnsplit(FromName,drive,dir,name,ext);
  do
    strcpy(ToName1,MakeName(name,++count));
  while (exist(ToName1));
  do
    strcpy(ToName2,MakeName(name,++count));
  while (exist(ToName2));
} /* ParseName */

/* =================================================== */
void SplitFile(char *Name)
{
  FILE *infile, *outfile1, *outfile2;
  string Name1, Name2;
  unsigned int NumRead, NumWritten;
  long int Size, FPos;

  buf = malloc(bufsize);
  ParseName(Name, Name1, Name2);
  infile = fopen(Name,"r");
  if (setvbuf(infile,buf,_IOFBF,bufsize) != 0)
  {
     puts("Could not allocate file buffer! Exiting.\n");
     exit(10);
  }
  Size = filelength(fileno(infile));
  outfile1 = fopen(Name1,"w");
  outfile2 = fopen(Name2,"w");
  printf("Copying %ld bytes", Size);
  do
  {
      NumRead    = fread (buf, 1, bufsize, infile);
      NumWritten = fwrite(buf, 1, NumRead, outfile1);
      FPos = ftell(infile);
  }
  while (FPos < (Size / 2) );
  fclose(outfile1);
  do
  {
      NumRead    = fread (buf, 1, bufsize, infile);
      NumWritten = fwrite(buf, 1, NumRead, outfile2);
  }
  while ((NumRead > 0) && (NumWritten == NumRead));
  fclose(outfile2);

} /* SplitFile */

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
void CleanUp(void)
/* restore original directory */
{
   if (buf != NULL)
     free(buf);
   buf = NULL;
}

/* =================================================== */
int main(int argc, char *argv[])
{
  if ((argc < 2) || (strcmp(argv[1],"?") == 0) || (exist(argv[1])==0) )
  {
    puts("usage: SPLIT FileName");
    return(10);
  };

   /* Install Termination Code */
  if (atexit(&CleanUp) == 0)
     SplitFile(argv[1]);

  return(0);
} /*SPLIT*/