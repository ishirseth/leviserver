//My amazing first C++ program

#include <iostream>
#include <cstdlib>
#include <ctime>

int num = 0;
char newGame = 'n';
int randomNum = 0;

void guess(){
    randomNum = (rand() % 100) + 1;
    
    while (true)
    {
        std::cout << "? ";
        std::cin >> num;
        
        if (num > randomNum){
            std::cout << "LOWER\n";
        }
        else if (num < randomNum){
            std::cout << "HIGHER\n";
        }
        else if (num == randomNum){
            std::cout << "LEVI!\n";
            break;
        }
        else{
            std::cout << "INVALID\n";
        }
    }

    return;
}

int main(){
    srand(time(0));
    while (true){
        std::cout << "NEW GAME? ";
        std::cin >> newGame;
        if (newGame == 'n'){
            return 0;
        }
        else if (newGame == 'y'){
            guess();
        }
        else{
            std::cout << "INVALID\n";
        }
    }
}
