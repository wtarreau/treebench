/*
 * Elastic Binary Trees - exported functions for operations on 32bit nodes.
 * Version 6.0.6
 * (C) 2002-2011 - Willy Tarreau <w@1wt.eu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation, version 2.1
 * exclusively.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

/* Consult eb32tree.h for more details about those functions */

#include "eb32tree.h"

struct eb32_node *eb32_insert(struct eb_root *root, struct eb32_node *new)
{
	return __eb32_insert(root, new);
}

struct eb32_node *eb32i_insert(struct eb_root *root, struct eb32_node *new)
{
	return __eb32i_insert(root, new);
}

struct eb32_node *eb32_lookup(struct eb_root *root, u32 x)
{
	return __eb32_lookup(root, x);
}

struct eb32_node *eb32i_lookup(struct eb_root *root, s32 x)
{
	return __eb32i_lookup(root, x);
}

/*
 * Find the last occurrence of the highest key in the tree <root>, which is
 * equal to or less than <x>. NULL is returned is no key matches.
 */
struct eb32_node *eb32_lookup_le(struct eb_root *root, u32 x)
{
	struct eb32_node *node;
	eb_troot_t *troot;
	u32 y, z;

	troot = root->b[EB_LEFT];
	if (unlikely(troot == NULL))
		return NULL;

	while (1) {
		if (unlikely(eb_gettag(troot) == EB_LEAF)) {
			/* We reached a leaf, which means that the whole upper
			 * parts were common. We will return either the current
			 * node or its next one if the former is too small.
			 */
			node = container_of(eb_untag(troot, EB_LEAF),
					    struct eb32_node, node.branches);
			if (node->key <= x)
				return node;
			/* return prev */
			troot = node->node.leaf_p;
			break;
		}
		node = container_of(eb_untag(troot, EB_NODE),
				    struct eb32_node, node.branches);

		__builtin_prefetch(node->node.branches.b[0], 0);
		__builtin_prefetch(node->node.branches.b[1], 0);

		y = node->key;
		z = 1U << (node->node.bit & 31);
		troot = (x & z) ? node->node.branches.b[1] : node->node.branches.b[0];

		if (node->node.bit < 0) {
			/* We're at the top of a dup tree. Either we got a
			 * matching value and we return the rightmost node, or
			 * we don't and we skip the whole subtree to return the
			 * prev node before the subtree. Note that since we're
			 * at the top of the dup tree, we can simply return the
			 * prev node without first trying to escape from the
			 * tree.
			 */
			if (node->key <= x) {
				troot = node->node.branches.b[EB_RGHT];
				while (eb_gettag(troot) != EB_LEAF)
					troot = (eb_untag(troot, EB_NODE))->b[EB_RGHT];
				return container_of(eb_untag(troot, EB_LEAF),
						    struct eb32_node, node.branches);
			}
			/* return prev */
			troot = node->node.node_p;
			break;
		}

		if ((x ^ y) & -(z << 1)) {
			/* No more common bits at all. Either this node is too
			 * small and we need to get its highest value, or it is
			 * too large, and we need to get the prev value.
			 */
			if ((node->key >> node->node.bit) < (x >> node->node.bit)) {
				troot = node->node.branches.b[EB_RGHT];
				return eb32_entry(eb_walk_down(troot, EB_RGHT), struct eb32_node, node);
			}

			/* Further values will be too high here, so return the prev
			 * unique node (if it exists).
			 */
			troot = node->node.node_p;
			break;
		}
	}

	/* If we get here, it means we want to report previous node before the
	 * current one which is not above. <troot> is already initialised to
	 * the parent's branches.
	 */
	while (eb_gettag(troot) == EB_LEFT) {
		/* Walking up from left branch. We must ensure that we never
		 * walk beyond root.
		 */
		if (unlikely(eb_clrtag((eb_untag(troot, EB_LEFT))->b[EB_RGHT]) == NULL))
			return NULL;
		troot = (eb_root_to_node(eb_untag(troot, EB_LEFT)))->node_p;
	}
	/* Note that <troot> cannot be NULL at this stage */
	troot = (eb_untag(troot, EB_RGHT))->b[EB_LEFT];
	node = eb32_entry(eb_walk_down(troot, EB_RGHT), struct eb32_node, node);
	return node;
}

/*
 * Find the first occurrence of the lowest key in the tree <root>, which is
 * equal to or greater than <x>. NULL is returned is no key matches.
 */
struct eb32_node *eb32_lookup_ge(struct eb_root *root, u32 x)
{
	struct eb32_node *node;
	eb_troot_t *troot;
	u32 y, z;

	troot = root->b[EB_LEFT];
	if (unlikely(troot == NULL))
		return NULL;

	while (1) {
		if (unlikely(eb_gettag(troot) == EB_LEAF)) {
			/* We reached a leaf, which means that the whole upper
			 * parts were common. We will return either the current
			 * node or its next one if the former is too small.
			 */
			node = container_of(eb_untag(troot, EB_LEAF),
					    struct eb32_node, node.branches);
			if (node->key >= x)
				return node;
			/* return next */
			troot = node->node.leaf_p;
			break;
		}
		node = container_of(eb_untag(troot, EB_NODE),
				    struct eb32_node, node.branches);

		__builtin_prefetch(node->node.branches.b[0], 0);
		__builtin_prefetch(node->node.branches.b[1], 0);

		y = node->key;
		z = 1U << (node->node.bit & 31);
		troot = (x & z) ? node->node.branches.b[1] : node->node.branches.b[0];

		if (node->node.bit < 0) {
			/* We're at the top of a dup tree. Either we got a
			 * matching value and we return the leftmost node, or
			 * we don't and we skip the whole subtree to return the
			 * next node after the subtree. Note that since we're
			 * at the top of the dup tree, we can simply return the
			 * next node without first trying to escape from the
			 * tree.
			 */
			if (node->key >= x) {
				troot = node->node.branches.b[EB_LEFT];
				while (eb_gettag(troot) != EB_LEAF)
					troot = (eb_untag(troot, EB_NODE))->b[EB_LEFT];
				return container_of(eb_untag(troot, EB_LEAF),
						    struct eb32_node, node.branches);
			}
			/* return next */
			troot = node->node.node_p;
			break;
		}

		if ((x ^ y) & -(z << 1)) {
			/* No more common bits at all. Either this node is too
			 * large and we need to get its lowest value, or it is too
			 * small, and we need to get the next value.
			 */
			if ((node->key >> node->node.bit) > (x >> node->node.bit)) {
				troot = node->node.branches.b[EB_LEFT];
				return eb32_entry(eb_walk_down(troot, EB_LEFT), struct eb32_node, node);
			}

			/* Further values will be too low here, so return the next
			 * unique node (if it exists).
			 */
			troot = node->node.node_p;
			break;
		}
	}

	/* If we get here, it means we want to report next node after the
	 * current one which is not below. <troot> is already initialised
	 * to the parent's branches.
	 */
	while (eb_gettag(troot) != EB_LEFT)
		/* Walking up from right branch, so we cannot be below root */
		troot = (eb_root_to_node(eb_untag(troot, EB_RGHT)))->node_p;

	/* Note that <troot> cannot be NULL at this stage */
	troot = (eb_untag(troot, EB_LEFT))->b[EB_RGHT];
	if (eb_clrtag(troot) == NULL)
		return NULL;

	node = eb32_entry(eb_walk_down(troot, EB_LEFT), struct eb32_node, node);
	return node;
}
