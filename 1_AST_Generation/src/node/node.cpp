#include "node.h"
using namespace std;
Node::Node(){}
Node::Node(int id, const std::string &title, int lineno)
{
    this->id = id;
    this->title = title;
    this->lineno = lineno;
    this->parent = nullptr;
    this->lexval = "";
}
Node::Node(int id, const std::string &title, int lineno, const std::string &lexval)
{
    this->id = id;
    this->title = title;
    this->lineno = lineno;
    this->parent = nullptr;
    this->lexval = lexval;
}
void Node::push_back(Node *&child)
{
    if (child != nullptr)
    {
        (this->child).push_back(child);
        child->parent = this;
    }
}
void Node::push_front(Node *&child)
{
    if (child != nullptr)
    {
        (this->child).push_front(child);
        child->parent = this;
    }
}