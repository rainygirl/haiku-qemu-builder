#ifndef QEMU_BUILD_LIBINTL_H
#define QEMU_BUILD_LIBINTL_H

#ifdef __cplusplus
extern "C" {
#endif

char *gettext(const char *message);
char *dgettext(const char *domain, const char *message);
char *dcgettext(const char *domain, const char *message, int category);
char *ngettext(const char *msgid1, const char *msgid2, unsigned long n);
char *dngettext(const char *domain, const char *msgid1,

    const char *msgid2, unsigned long n);
char *dcngettext(const char *domain, const char *msgid1,

    const char *msgid2, unsigned long n, int category);
char *textdomain(const char *domainname);
char *bindtextdomain(const char *domainname, const char *dirname);
char *bind_textdomain_codeset(const char *domainname, const char *codeset);

#ifdef __cplusplus
}
#endif

#endif
