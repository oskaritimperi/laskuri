#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#if defined(_WIN32)
#define PATH_SEP "\\"
#else
#define PATH_SEP "/"
#endif

#if !defined(_WIN32)
#define EXE_SUFFIX ""
#else
#define EXE_SUFFIX ".exe"
#endif

#if !defined(_WIN32)
#include <errno.h>
#endif

#if defined(_WIN32)
#include <windows.h>

static char *utf8_to_wide(const char *s)
{
    // TODO: utf8_to_wide
}

static char *wide_to_utf8(const wchar_t *ws)
{
    char *utf8 = NULL;
    DWORD rc;

    rc = WideCharToMultiByte(CP_UTF8, 0, ws, -1, NULL, 0, NULL, NULL);

    if (rc == 0xfffd)
    {
        return NULL;
    }
    else if (rc == 0)
    {
        if (GetLastError() != ERROR_INSUFFICIENT_BUFFER)
        {
            return NULL;
        }
    }

    utf8 = malloc(rc);

    WideCharToMultiByte(CP_UTF8, 0, ws, -1, utf8, rc, NULL, NULL);

    return utf8;
}

static char *get_exe_path()
{
    wchar_t *buffer = NULL;
    DWORD bufsz = 1024;
    char *path = NULL;

    while (1)
    {
        DWORD ret;

        wchar_t *newbuffer = realloc(buffer, bufsz*sizeof(wchar_t));
        if (!newbuffer)
        {
            free(buffer);
            return NULL;
        }

        buffer = newbuffer;

        ret = GetModuleFileNameW(NULL, buffer, bufsz);

        if (ret == 0)
        {
            return NULL;
        }

        if (ret == bufsz)
        {
            bufsz *= 2;
        }
        else
        {
            break;
        }
    }

    path = wide_to_utf8(buffer);

    free(buffer);

    return path;
}
#endif

#if defined(__gnu_linux__)
#include <unistd.h>

static char *get_exe_path()
{
    char *buffer = NULL;
    size_t bufsz = 1024;

    while (1)
    {
        ssize_t l;

        char *newbuffer = realloc(buffer, bufsz);
        if (!newbuffer)
        {
            free(buffer);
            return NULL;
        }

        buffer = newbuffer;

        if ((l = readlink("/proc/self/exe", buffer, bufsz)) == -1)
        {
            free(buffer);
            return NULL;
        }

        if (l == bufsz)
        {
            bufsz *= 2;
        }
        else
        {
            buffer[l] = '\0';
            break;
        }
    }

    return buffer;
}
#endif

#if defined(__APPLE__)
#include <unistd.h>
#include <mach-o/dyld.h>

static char *get_exe_path()
{
    char *buffer = NULL;
    uint32_t bufsz = 0;
    _NSGetExecutablePath(buffer, &bufsz)
    buffer = malloc(bufsz);
    _NSGetExecutablePath(buffer, &bufsz);
    return buffer;
}
#endif

static char *dirname(const char *path)
{
    char *dir;
    char sep = PATH_SEP[0];
    char *psep = strrchr(path, sep);

    // No path separator
    if (!psep)
    {
        // TODO: C:foo => C:
        return NULL;
    }

    // \foo  => \
    // /some => /
    if (psep == path)
    {
        char buf[] = { sep, 0 };
        return strdup(buf);
    }

#if defined(_WIN32)
    // C:\foo => C:\
    // C:\    => C:\

    if (psep[-1] == ':')
    {
        dir = malloc(psep - path + 1 + 1);
        memcpy(dir, path, psep - path + 1);
        dir[psep - path + 1] = '\0';
        return dir;
    }
#endif

    // C:\foo\bar => C:\foo
    // /foo/bar   => /foo

    dir = malloc(psep - path + 1);
    memcpy(dir, path, psep - path);
    dir[psep - path] = '\0';
    return dir;
}

char *pathjoin(const char *base, ...)
{
    va_list ap;
    char *result = strdup(base);
    size_t result_len = strlen(result);

    va_start(ap, base);

    while (1)
    {
        const char *part = va_arg(ap, const char *);
        size_t part_len;
        char *newresult;

        if (!part)
            break;

        part_len = strlen(part);

        newresult = realloc(result, result_len + 1 + part_len + 1);
        if (!newresult)
        {
            free(result);
            va_end(ap);
            return NULL;
        }

        result = newresult;

        result[result_len] = PATH_SEP[0];
        ++result_len;

        memcpy(result+result_len, part, part_len);

        result_len += part_len;

        result[result_len] = '\0';
    }

    va_end(ap);

    return result;
}

int main(int argc, char **argv)
{
    char *exe = get_exe_path();
    char *dir = dirname(exe);
    char *mkpdf = pathjoin(dir, "bin", "mkpdf" EXE_SUFFIX, NULL);
    char *laskuri = pathjoin(dir, "laskuri.lua");

#if !defined(_WIN32)
    execl(mkpdf, mkpdf, laskuri, NULL);
    // if execl returns, it failed.
    fprintf(stderr, "error: %s\n", strerror(errno));
    return 1;
#else
    char *cmdline = malloc(strlen(mkpdf) + 1 + strlen(laskuri) + 1);
    memcpy(cmdline, mkpdf, strlen(mkpdf));
    cmdline[strlen(mkpdf)] = ' ';
    memcpy(cmdline+strlen(mkpdf)+1, laskuri, strlen(laskuri));
    cmdline[strlen(mkpdf)+1+strlen(laskuri)] = '\0';

    // TODO: Use CreateProcessW
    CreateProcessA(mkpdf, cmdline, NULL, NULL, TRUE, 0, NULL, NULL, NULL, NULL);

    free(cmdline);
    free(laskuri);
    free(mkpdf);
    free(dir);
    free(exe);

    return 0;
#endif
}
