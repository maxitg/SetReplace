// Executable that reads rules, a graph, and a step count from a file, and writes the output graph to another file

#include "Set.hpp"

#include <fstream>
#include <iostream>

namespace SetReplace {
    Expression readExpression(std::ifstream& stream) {
        int count;
        stream >> count;
        std::vector<AtomID> atoms(count);
        for (AtomID& atom : atoms) {
            stream >> atom;
        }
        return Expression(atoms);
    }
    
    std::vector<Expression> readExpressions(std::ifstream& stream) {
        int count;
        stream >> count;
        std::vector<Expression> expressions;
        for (int i = 0; i < count; ++i) {
            expressions.push_back(readExpression(stream));
        }
        return expressions;
    }
    
    Rule readRule(std::ifstream& stream) {
        return {readExpressions(stream), readExpressions(stream)};
    }
    
    std::vector<Rule> readRules(std::ifstream& stream) {
        int count;
        stream >> count;
        std::vector<Rule> rules;
        for (int i = 0; i < count; ++i) {
            rules.push_back(readRule(stream));
        }
        return rules;
    }
    
    Set readInput(const std::string& filename) {
        std::ifstream stream(filename);
        const auto rules = readRules(stream);
        const auto initialExpressions = readExpressions(stream);
        return Set(rules, initialExpressions);
    }
    
    void writeExpression(std::ofstream& stream, const Expression expression) {
        stream << expression.size();
        for (const auto& atom : expression) {
            stream << " " << atom;
        }
        stream << std::endl;
    }
    
    void writeExpressions(std::ofstream& stream, const std::vector<Expression>& expressions) {
        stream << expressions.size() << std::endl;
        for (const auto& expression : expressions) {
            writeExpression(stream, expression);
        }
    }
    
    void writeOutput(const std::string& filename, const Set output) {
        std::ofstream stream(filename);
        writeExpressions(stream, output.expressions());
    }
}

int main(int argc, const char * argv[]) {
    if (argc != 4) std::cerr << "3 arguments expected: input file, output file, and step count.";
    SetReplace::writeOutput(std::string(argv[3]), SetReplace::readInput(std::string(argv[1])).replace(std::stoi(argv[2])));
    return 0;
}
