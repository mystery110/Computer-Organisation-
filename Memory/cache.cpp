#include<iostream>
#include<fstream>
#include<string>
#include<vector>
#include<sstream>
#include<bitset>
using namespace std;

static int setNumber;
static int associative ;
static int wordPerBlock;
static int cacheSize;
static int blockNumber;
static int setOffset;
static int replacePolicy;
static int wordOffset;
static int tagOffset;


int CalculateNumberOfBit(int);

class Block{
	public :
		Block(){
			valid=false;
			rereferance=false;
		}

		bool getValid(){
			return valid;
		}

		void setValid(){
			valid=true;
		}

		void RereferenceIncrement(){
			rereferance++;
		}

		void setRereference(int value){
			rereferance=value;
		}

		int getRereferance(){
			return rereferance;
		}
		int getTag(){
			return tag;
		}

		void setTag(int tag_func){
			tag=tag_func;
		}
	private :
		int tag;
		bool valid;
		int rereferance;

};

class Set{
	public :
		Set(){
			switch(associative){
				case 0:{
						   Block tempBlock;
						   blockWithin.push_back(tempBlock);
						   break;}

				case 1:{
						   for (int i=0;i<4;i++){
							   Block tempBlock;
							   blockWithin.push_back(tempBlock);
						   }
						   break;
					   }
				case 2:{
						   for (int i=0;i<blockNumber;i++){
							   Block tempBlock;
							   blockWithin.push_back(tempBlock);
						   }
						   break;
					   }
			}
		}

		int CheckAllValid(){
			unsigned int i=0;
			for(;i<blockWithin.size();i++){
				if(blockWithin.at(i).getValid()==false){
					break;
				}
			}
			if(i==blockWithin.size()){
				return -1;
			}
			else {
				return i;
			}
		}

		int FindBlock(int tag_func){
			unsigned int i=0;
			for (;i<blockWithin.size();i++){
				if(blockWithin.at(i).getTag()==tag_func){
					return i;
				}
			}
				return -1;
		}

		int updateSet(int tag_func){
			int tagreturn=-1;
			int index;
			if((index=FindBlock(tag_func))==-1){
					if((index=CheckAllValid())==-1){
						index=Priority.at(0);
						Priority.erase(Priority.begin());
						tagreturn=blockWithin.at(index).getTag();
						blockWithin.at(index).setTag(tag_func);
						blockWithin.at(index).setValid();
						updateProirity(index);
						blockWithin.at(index).setRereference(0);
					}
					else {
						blockWithin.at(index).setTag(tag_func);
						blockWithin.at(index).setValid();
						updateProirity(index);
						blockWithin.at(index).setRereference(0);
					}
			}
			else {
				blockWithin.at(index).RereferenceIncrement();
				updateProirity(index);

			}
			return tagreturn;
		}

		void updateProirity(int recentUsedBlockNumber){
			unsigned int index=0;
			if(Priority.size()>0){
				for(;index<Priority.size();index++){
					if(Priority.at(index)==recentUsedBlockNumber){
						break;
					}
				}
			}
			switch(replacePolicy){
				
				case 0:{
						   if(index==Priority.size()){
							   Priority.push_back(recentUsedBlockNumber);
						   }
					   break;
					   }
				case 1:{
						   if(index==Priority.size()){
							   Priority.push_back(recentUsedBlockNumber);

						   }
						   else {
							   Priority.erase(Priority.begin()+index);
							   Priority.push_back(recentUsedBlockNumber);
						   }
						   break;
					   }
				case 2:{
						   if(PriorityIsFULL==false && index==Priority.size()){
							   Priority.push_back(recentUsedBlockNumber);
						   }
						   if(Priority.size()==blockWithin.size()){
							   PriorityIsFULL=true;
						   }
						   if(PriorityIsFULL==true){
							   if(index==Priority.size()){
								   Priority.insert(Priority.begin()+(blockWithin.size()/2)-1,recentUsedBlockNumber);
							   }
							   else {
								   Priority.erase(Priority.begin()+index);
								   Priority.push_back(recentUsedBlockNumber);
							   }
						   }

						   
						   break;
					   }
			}
		}


	private :
		vector<Block>blockWithin;
		vector<int>Priority;
		bool PriorityIsFULL=false;
		 

};

class Cache{
	public:
		Cache(){
			for(int i=0;i<setNumber;i++){
				Set tempSet;
				setWithin.push_back(tempSet);
			}
		}

		int FindBlock(int setnumber_func,int tag_func){
			return setWithin.at(setnumber_func).updateSet(tag_func);
		}
	private:
		vector<Set>setWithin;
};


int main (int argc,char *args[]){
	ifstream inputFile;
	string tempString;
	stringstream ss;
	int index;
	int tag;
	unsigned int tempInt;


	if(argc <2){
		cout<<"Enter Valid File"<<endl;
	}
	//Open File
	try{
		inputFile.open(args[1]);
	}
	catch(exception e){
		cout<<"No File Found"<<endl;
		exit(0);
	}

	ofstream outputFile(args[2]);

	//initialize variable
	inputFile>>cacheSize;
	cacheSize*=1024;
	getline(inputFile,tempString);//getrid of \n


	getline(inputFile,tempString);//getByte
	wordPerBlock=stoi(tempString)/4;
	wordOffset=CalculateNumberOfBit(wordPerBlock);
	blockNumber=cacheSize/stoi(tempString);

	inputFile>>associative;
	getline(inputFile,tempString);
	
	switch(associative){
		case 0:
			setNumber=blockNumber;
			setOffset=CalculateNumberOfBit(setNumber);
			break;
		case 1:
			setNumber=blockNumber/4;

			setOffset=CalculateNumberOfBit(setNumber);
			break;
		case 2:
			setNumber=1;
			setOffset=0;
			break;
	}
	tagOffset=32-2-wordOffset-setOffset;

	
	inputFile>>replacePolicy;
	getline(inputFile,tempString);

	Cache cacheExist;


	while(getline(inputFile,tempString)){
		ss<<hex<<tempString;
		ss>>tempInt;
		bitset<32> b(tempInt);
		if(setOffset>0){
			index=stoull(b.to_string().substr(tagOffset,setOffset),NULL,2);
		}
		else {
			index=0;
		}
		tag=stoull(b.to_string().substr(0,tagOffset),NULL,2);
		outputFile<<cacheExist.FindBlock(index,tag)<<endl;
		ss.clear();
	}
	inputFile.close();
	outputFile.close();
}

int CalculateNumberOfBit(int number){
	int i=1,ans=2;
	while((ans=ans*2)<=number){
		i++;
	}
	return i;
}



