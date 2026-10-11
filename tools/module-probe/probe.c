// SPDX-License-Identifier: GPL-2.0
/* Minimal module to check that we build modules the vendor kernel accepts */
#include <linux/module.h>
#include <linux/kernel.h>

static int __init probe_init(void)
{
	pr_info("miyoo probe module loaded\n");
	return 0;
}

static void __exit probe_exit(void)
{
	pr_info("miyoo probe module unloaded\n");
}

module_init(probe_init);
module_exit(probe_exit);
MODULE_LICENSE("GPL");
