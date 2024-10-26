// Header guards prevent multiple inclusions of this file, avoiding redefinition errors.
#ifndef NODE_H
#define NODE_H
#include <bits/stdc++.h>
class Node
{
public:
    int id;
    int lineno;
    std::string title, lexval;
    Node *parent;
    std::deque<Node *> child;

    //symbol table req. starts
    std::string lvalue;
    std::string rvalue;

    int if_executed_jump;
    int if_not_executed_jump;
    std::string else_block_label;

    int size_of_params;
    int begin_func_idx;
    std::vector<int> break_jumps;
    // symbol table req. ends

    Node();
    Node(int id, const std::string &title, int lineno);
    Node(int id, const std::string &title, int lineno, const std::string &lexval);
    // Add a child node to the back
    void push_back(Node *&child);
    // Add a child node to the front
    void push_front(Node *&child);
};
#endif