module quizzes::quiz {
    use std::string::{utf8, String};
    use sui::package;
    use sui::display;

    // Quiz that can be created by anyone
    public struct Quiz has key, store {
        id: UID,
        hash_id: String,
        title: String,
        description: String,
        image_url: String,
        checksum: String,
        create_time: u64,
        is_ended: bool,
        game: vector<Game>,
    }

    // Game that can be created in quiz
    public struct Game has key, store {
        id: UID,
        time: u64,
        scoreboard: vector<Record>
    }

    // Struct Record include username/useraddress and score in game
    public struct Record has copy, drop, store {
        user: String,
        score: u64
    }

    public struct QUIZ has drop {}

    fun init(otw: QUIZ, ctx: &mut TxContext){
        let keys = vector [
            utf8(b"title"),
            utf8(b"description"),
            utf8(b"image_url"),
            utf8(b"checksum"),
        ];
        let values = vector[
            utf8(b"{title}"),
            utf8(b"{description}"),
            utf8(b"{image_url}"),
            utf8(b"{checksum}"),
        ];

        //claim Publisher for package
        let publisher = package::claim(otw, ctx);

        //get a Display object for Quiz type
        let mut display = display::new_with_fields<Quiz>(
            &publisher, keys, values, ctx
        );

        //commit first version of Display to apply change
        display::update_version(&mut display);

        let sender = tx_context::sender(ctx);
        transfer::public_transfer(publisher, sender);
        transfer::public_transfer(display, sender);

    }

    // Create quiz with content from input and empty game attribute
    // Quiz object will be transferred to sender
    public entry fun create_quiz(hash_id: String, title: String, description: String, image_url: String, checksum: String, ctx: &mut TxContext) {
        let quiz = Quiz {
            id: object::new(ctx),
            hash_id,
            title,
            description,
            image_url,
            checksum,
            create_time: tx_context::epoch_timestamp_ms(ctx),
            is_ended: false,
            game: vector::empty(),
        };
        transfer::transfer(quiz, tx_context::sender(ctx))
    }

    // modify info of quiz
    // if data is changed, it will be reverted
    public entry fun modify_quiz(current_checksum:String, new_checksum: String, title: String, description: String, image_url: String, quiz: &mut Quiz){
        assert!(current_checksum==quiz.checksum,0);
        quiz.title = title;
        quiz.description = description;
        quiz.image_url = image_url;
        quiz.checksum = new_checksum
    }

    // create new game object in quiz object 
    // length of array of users and scores  must be equal, otherwise it will revert
    public entry fun create_game(users: vector<String>, scores: vector<u64>, quiz: &mut Quiz, ctx: &mut TxContext){
        let usersLen = users.length();
        let scoresLen = scores.length();
        let mut i:u64 = 0;
        assert!(usersLen == scoresLen, 0);
        let mut new_score_board = vector<Record>[];
        while (i < usersLen) {
            new_score_board.push_back(
                Record {
                    user: users[i],
                    score: scores[i]
                }
            );
            i = i + 1;
        };
        let game = Game {
            id: object::new(ctx),
            time: tx_context::epoch_timestamp_ms(ctx),
            scoreboard: new_score_board
        };
        quiz.game.push_back(game);
    }

    // delete quiz 
    public entry fun delete_quiz(quiz: Quiz, _ctx: &mut TxContext) {
        let Quiz {id, hash_id: _, title: _, description: _, image_url: _, checksum: _,create_time: _, is_ended: _, mut game} = quiz;
        let mut i = 0;
        let len = game.length();
        while (i < len ) {
            let Game {id: id_game, time: _, scoreboard: _} = game.pop_back();
            object::delete(id_game);
            i = i + 1;
        } ;
        game.destroy_empty();
        object::delete(id)
    }

    // get title of quiz object
    public fun title(quiz: &Quiz): &String {
        &quiz.title
    }

    // get description of quiz object
    public fun description(quiz: &Quiz): &String {
        &quiz.description
    }

    // get image_url of quiz object
    public fun image_url(quiz: &Quiz): &String {
        &quiz.image_url
    }

    // get checksum of quiz object
    public fun checksum(quiz: &Quiz): &String {
        &quiz.checksum
    }

    // get hash_id of quiz object
    public fun hash_id(quiz: &Quiz): &String {
        &quiz.hash_id
    }

    // get scoreboard of game object
    public fun scoreboard(game: &Game): & vector<Record> {
        &game.scoreboard
    }
}
