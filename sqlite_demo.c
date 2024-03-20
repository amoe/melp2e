#include <stdio.h>
#include <sqlite3.h>

int main(int argc, char **argv) {
    sqlite3 *db;
    int rc;
    rc = sqlite3_open("test.db", &db);
    printf("yes\n");
}
