#!/usr/bin/env python3

import getpass
import argon2

print(argon2.hash_password(getpass.getpass().encode("utf-8")).decode("utf-8"))