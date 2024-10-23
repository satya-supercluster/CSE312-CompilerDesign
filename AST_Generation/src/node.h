// Header guards prevent multiple inclusions of this file, avoiding redefinition errors.
#ifndef HEADER_GUARD_NODE
#define HEADER_GUARD_NODE
#include <string>
#include <deque>
class Node
{
private:
    int id;
    int lineno;
    std::string title, lexval;
    Node *parent;
    std::deque<Node *> child;

public:
    Node() {}
    Node(int id, const std::string &title, int lineno)
    {
        this->id = id;
        this->title = title;
        this->lineno = lineno;
        this->parent = nullptr;
        this->lexval = "";
    }
    Node(int id, const std::string &title, int lineno, const std::string &lexval)
    {
        this->id = id;
        this->title = title;
        this->lineno = lineno;
        this->parent = nullptr;
        this->lexval = lexval;
    }
    // Add a child node to the back
    void push_back(Node *&child)
    {
        if (child != nullptr)
        {
            (this->child).push_back(child);
            child->parent = this;
        }
    }
    // Add a child node to the front
    void push_front(Node *&child)
    {
        if (child != nullptr)
        {
            (this->child).push_front(child);
            child->parent = this;
        }
    }
};
#endif